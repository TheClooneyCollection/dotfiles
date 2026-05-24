#!/usr/bin/env python3
"""TUI theme picker and manager for Ghostty.

Two-column layout: dark themes on the left, light themes on the right.
Navigate with arrow keys or j/k within a column, h/l to switch columns.
Ctrl-D/Ctrl-U for half-page scrolling.
Enter to save, Esc/q to cancel and restore the original theme.

Keys:
    * = star/unstar a favorite
    x = remove from favorites/starred
    Space = add unreviewed theme to favorites
"""

import curses
import os
import re
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
CONFIG = SCRIPT_DIR / "config"
YAML_FILE = SCRIPT_DIR / "themes.yaml"
ALL_THEMES_FILE = SCRIPT_DIR / "all-themes.txt"
CLASSIFIED_FILE = SCRIPT_DIR / "classified-themes.yaml"
THEMES_DIR = Path("/Applications/Ghostty.app/Contents/Resources/ghostty/themes")

# Color pair IDs mapped to ANSI palette colors.
C_NORMAL = 0
C_RED = 2
C_GREEN = 3
C_YELLOW = 4
C_BLUE = 5
C_MAGENTA = 6
C_CYAN = 7
C_GRAY = 8        # bright black (palette 8)
C_HIGHLIGHT = 9    # list selection
C_STATUSBG = 10    # status bar segments
C_DIM = 11         # dimmed text for unfocused column

# Box-drawing chars
BOX_TL = "\u250c"  # +
BOX_TR = "\u2510"  # +
BOX_BL = "\u2514"  # +
BOX_BR = "\u2518"  # +
BOX_H = "\u2500"   # -
BOX_V = "\u2502"   # |
BOX_ML = "\u251c"  # +
BOX_MR = "\u2524"  # +

# Width of the bat-style code box (interior)
BOX_W = 48
GUTTER_W = 4  # " 1 |"

# Code lines: list of (text, color_pair_id) segments per line.
CODE_LINES = [
    [("import ", C_MAGENTA), ("os", C_NORMAL)],
    [("from ", C_MAGENTA), ("pathlib ", C_NORMAL),
     ("import ", C_MAGENTA), ("Path", C_CYAN)],
    [],
    [("def ", C_MAGENTA), ("greet", C_BLUE),
     ("(", C_NORMAL), ("name", C_RED), (": ", C_NORMAL),
     ("str", C_CYAN), (") -> ", C_NORMAL), ("str", C_CYAN),
     (":", C_NORMAL)],
    [("    ", C_NORMAL), ("# Say hello", C_GRAY)],
    [("    ", C_NORMAL), ("if ", C_MAGENTA),
     ("name ", C_NORMAL), ("== ", C_RED),
     ('"world"', C_GREEN), (":", C_NORMAL)],
    [("        ", C_NORMAL), ("return ", C_MAGENTA),
     ("f", C_GREEN), ('"Hello, ', C_GREEN), ("{", C_NORMAL),
     ("name", C_RED), ("}", C_NORMAL), ('!"', C_GREEN)],
    [("    ", C_NORMAL), ("count", C_NORMAL),
     (" = ", C_RED), ("42", C_YELLOW)],
]

PROMPT_SEGMENTS = [
    (" ~/projects ", C_BLUE, True),
    (" on ", C_NORMAL, False),
    (" \ue0a0 main ", C_MAGENTA, False),
    ("[+] ", C_YELLOW, False),
    ("via ", C_NORMAL, False),
    ("v3.12 ", C_GREEN, False),
    ("\u276f ", C_CYAN, False),
]

BODY_TEXT = (
    "Lorem ipsum dolor sit amet, consectetur adipiscing elit. "
    "Cras hendrerit aliquet turpis non dictum."
)


# --- Classification cache ---

def load_classified() -> dict[str, str]:
    """Load classified-themes.yaml, returns dict of name -> mode."""
    if not CLASSIFIED_FILE.exists():
        return {}
    result = {}
    for line in CLASSIFIED_FILE.read_text().splitlines():
        if line.startswith("#") or not line.strip():
            continue
        # Format: "Theme Name: dark" or "Theme Name: light"
        idx = line.rfind(": ")
        if idx == -1:
            continue
        name = line[:idx]
        mode = line[idx + 2:].strip()
        if mode in ("dark", "light"):
            result[name] = mode
    return result


def generate_classified() -> dict[str, str]:
    """Classify all themes with progress output, write cache, return dict."""
    if not ALL_THEMES_FILE.exists():
        return {}

    all_names = ALL_THEMES_FILE.read_text().splitlines()
    total = len(all_names)
    classified = {}
    for i, name in enumerate(all_names):
        if (i + 1) % 50 == 0 or i == total - 1:
            print(f"\rClassifying themes... {i + 1}/{total}", end="", flush=True)
        bg = parse_bg(name)
        if bg is None:
            continue
        mode, _ = classify(bg)
        classified[name] = mode
    print()  # newline after progress

    out_lines = ["# Auto-generated. Maps theme name -> mode."]
    for name in sorted(classified.keys(), key=str.lower):
        out_lines.append(f"{name}: {classified[name]}")
    out_lines.append("")
    CLASSIFIED_FILE.write_text("\n".join(out_lines))
    return classified


# --- YAML load/save ---

def load_yaml() -> dict:
    """Load themes.yaml into structured dict with review, starred, dark, light."""
    data = {"review": {}, "starred": [], "dark": [], "light": []}
    if not YAML_FILE.exists():
        return data

    text = YAML_FILE.read_text()
    current_section = None

    for line in text.splitlines():
        stripped = line.strip()
        if line.startswith("review:"):
            current_section = "review"
            continue
        if line.startswith("starred:"):
            current_section = "starred"
            continue
        if line.startswith("dark:"):
            current_section = "dark"
            continue
        if line.startswith("light:"):
            current_section = "light"
            continue
        if re.match(r"^[a-z]", line) and not line.startswith(" "):
            current_section = None
            continue

        if current_section == "review":
            m = re.match(r'\s+last_reviewed:\s*"(.+)"', line)
            if m:
                data["review"]["last_reviewed"] = m.group(1)
            m = re.match(r"\s+reviewed_count:\s*(\d+)", line)
            if m:
                data["review"]["reviewed_count"] = int(m.group(1))
            m = re.match(r"\s+total_count:\s*(\d+)", line)
            if m:
                data["review"]["total_count"] = int(m.group(1))

        elif current_section == "starred":
            m = re.match(r'\s+- "(.+)"', line)
            if m:
                data["starred"].append(m.group(1))

        elif current_section in ("dark", "light"):
            m = re.match(r'\s+- name: "(.+)"', line)
            if m:
                data[current_section].append({"name": m.group(1)})
            m = re.match(r'\s+background: "(.+)"', line)
            if m and data[current_section]:
                data[current_section][-1]["background"] = m.group(1)
            m = re.match(r"\s+bg_color: (.+)", line)
            if m and data[current_section]:
                data[current_section][-1]["bg_color"] = m.group(1)

    return data


def save_yaml(data: dict) -> None:
    """Write structured data back to themes.yaml."""
    review = data["review"]
    lines = [
        "# Managed by pick-theme.py",
        "",
        "review:",
        f'  last_reviewed: "{review.get("last_reviewed", "")}"',
        f"  reviewed_count: {review.get('reviewed_count', 0)}",
        f"  total_count: {review.get('total_count', 0)}",
        "",
        "starred:",
    ]
    for name in data["starred"]:
        lines.append(f'  - "{name}"')
    lines.append("")
    lines.append("dark:")
    for t in data["dark"]:
        lines.append(f'  - name: "{t["name"]}"')
        lines.append(f'    background: "{t["background"]}"')
        lines.append(f"    bg_color: {t['bg_color']}")
    lines.append("")
    lines.append("light:")
    for t in data["light"]:
        lines.append(f'  - name: "{t["name"]}"')
        lines.append(f'    background: "{t["background"]}"')
        lines.append(f"    bg_color: {t['bg_color']}")
    lines.append("")
    YAML_FILE.write_text("\n".join(lines))


# --- Theme classification (from generate script) ---

def parse_bg(theme_name: str) -> str | None:
    path = THEMES_DIR / theme_name
    if not path.exists():
        return None
    for line in path.read_text().splitlines():
        if line.startswith("background"):
            return line.split("=", 1)[1].strip()
    return None


def luminance(hex_color: str) -> float:
    h = hex_color.lstrip("#")
    r, g, b = int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)
    return 0.299 * r + 0.587 * g + 0.114 * b


def classify(hex_color: str) -> tuple[str, str]:
    h = hex_color.lstrip("#")
    r, g, b = int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)
    lum = luminance(hex_color)
    mode = "light" if lum > 128 else "dark"

    if lum > 200:
        if r > 240 and g > 240 and b > 240:
            label = "white"
        elif r > g > b:
            label = "cream"
        else:
            label = "light gray"
    elif lum > 140:
        label = "tan" if r > g > b else "light gray"
    elif lum < 40:
        if b > r and b > g:
            label = "dark blue"
        elif r > g > b and (r - b) > 15:
            label = "dark brown"
        else:
            label = "black"
    else:
        if b > r + 15 and b > g + 15:
            label = "blue"
        elif r < 60 and g > 80 and b > 100:
            label = "teal"
        elif b > r and b > g:
            label = "dark blue"
        else:
            label = "dark gray"

    return mode, label


def classify_theme(name: str) -> dict | None:
    """Classify a theme by reading its file. Returns dict with mode, background, bg_color."""
    bg = parse_bg(name)
    if bg is None:
        return None
    mode, label = classify(bg)
    return {"name": name, "mode": mode, "background": bg, "bg_color": label}


# --- Unreviewed themes ---

def load_unreviewed(last_reviewed: str) -> list[str]:
    """Return theme names from all-themes.txt that come after last_reviewed."""
    if not ALL_THEMES_FILE.exists():
        return []
    all_names = ALL_THEMES_FILE.read_text().splitlines()
    if not last_reviewed:
        return all_names

    try:
        idx = all_names.index(last_reviewed)
        return all_names[idx + 1:]
    except ValueError:
        return all_names


# --- List items ---

ITEM_STARRED = "starred"
ITEM_FAVORITE = "favorite"
ITEM_UNREVIEWED = "unreviewed"
ITEM_SEPARATOR = "separator"


def build_items(data: dict, unreviewed: list[str], mode: str,
                classifications: dict[str, str]) -> list[dict]:
    """Build display list for one column (dark or light)."""
    items = []

    # Starred section (filtered to this mode)
    for name in data["starred"]:
        theme_mode = classifications.get(name)
        if theme_mode is None:
            info = classify_theme(name)
            theme_mode = info["mode"] if info else None
        if theme_mode != mode:
            continue
        items.append({"type": ITEM_STARRED, "name": name})

    # Separator between starred and favorites
    if items:
        items.append({"type": ITEM_SEPARATOR, "label": "favorites"})

    # Favorites for this mode, excluding starred
    starred_set = set(data["starred"])
    section = data[mode]
    favorites = []
    for t in section:
        if t["name"] not in starred_set:
            favorites.append({"type": ITEM_FAVORITE, "name": t["name"],
                              "bg_color": t.get("bg_color", "")})
    favorites.sort(key=lambda x: x["name"].lower())
    items.extend(favorites)

    # Unreviewed section (filtered to this mode)
    mode_unreviewed = [n for n in unreviewed if classifications.get(n) == mode]
    if mode_unreviewed:
        items.append({"type": ITEM_SEPARATOR, "label": "unreviewed"})
        for name in mode_unreviewed:
            items.append({"type": ITEM_UNREVIEWED, "name": name})

    return items


# --- Config / theme application ---

def get_current_theme() -> str:
    for line in CONFIG.read_text().splitlines():
        if line.startswith("theme"):
            return line.split("=", 1)[1].strip()
    return ""


def reload_config() -> None:
    try:
        os.system("killall -USR2 ghostty 2>/dev/null")
    except OSError:
        pass


def set_theme(name: str) -> None:
    text = CONFIG.read_text()
    if re.search(r"^theme\s*=", text, re.MULTILINE):
        text = re.sub(r"^theme\s*=.*$", f"theme = {name}", text, flags=re.MULTILINE)
    else:
        text += f"\ntheme = {name}\n"
    CONFIG.write_text(text)
    reload_config()


# --- Curses rendering ---

def init_colors() -> None:
    curses.use_default_colors()
    curses.init_pair(C_RED, curses.COLOR_RED, -1)
    curses.init_pair(C_GREEN, curses.COLOR_GREEN, -1)
    curses.init_pair(C_YELLOW, curses.COLOR_YELLOW, -1)
    curses.init_pair(C_BLUE, curses.COLOR_BLUE, -1)
    curses.init_pair(C_MAGENTA, curses.COLOR_MAGENTA, -1)
    curses.init_pair(C_CYAN, curses.COLOR_CYAN, -1)
    curses.init_pair(C_GRAY, 8, -1)
    curses.init_pair(C_HIGHLIGHT, curses.COLOR_BLACK, curses.COLOR_CYAN)
    curses.init_pair(C_STATUSBG, curses.COLOR_BLACK, curses.COLOR_BLUE)
    curses.init_pair(C_DIM, 8, -1)  # same as gray for dimmed unfocused


def _addstr(stdscr, y, x, text, attr=0):
    """Safe addstr that avoids writing to the bottom-right corner."""
    h, w = stdscr.getmaxyx()
    if y >= h or x >= w:
        return x + len(text)
    maxlen = w - x - 1 if y == h - 1 else w - x
    if maxlen <= 0:
        return x + len(text)
    stdscr.addnstr(y, x, text, maxlen, attr)
    return x + len(text)


def draw_preview(stdscr, y, w) -> int:
    """Draw bat-style code box, prompt line, and body text. Returns next y."""
    box_w = min(BOX_W, w - 4)
    total_w = box_w + 2  # +2 for left/right border
    x0 = 1

    # -- "-> bat example.py" header --
    _addstr(stdscr, y, x0, "\u2192 ", curses.color_pair(C_CYAN))
    _addstr(stdscr, y, x0 + 2, "bat ", curses.color_pair(C_NORMAL))
    _addstr(stdscr, y, x0 + 6, "example.py", curses.color_pair(C_BLUE) | curses.A_UNDERLINE)
    y += 1

    # -- top border --
    header_text = " File: example.py "
    bar_left = (box_w - len(header_text)) // 2
    bar_right = box_w - len(header_text) - bar_left
    top = BOX_TL + BOX_H * bar_left + header_text + BOX_H * bar_right + BOX_TR
    _addstr(stdscr, y, x0, top, curses.color_pair(C_GRAY))
    y += 1

    # -- code lines inside box --
    for i, segments in enumerate(CODE_LINES):
        lineno = f" {i + 1} "
        _addstr(stdscr, y, x0, BOX_V, curses.color_pair(C_GRAY))
        _addstr(stdscr, y, x0 + 1, lineno, curses.color_pair(C_GRAY))
        _addstr(stdscr, y, x0 + 1 + len(lineno), BOX_V, curses.color_pair(C_GRAY))
        cx = x0 + 1 + len(lineno) + 1 + 1
        for text, color_id in segments:
            cx = _addstr(stdscr, y, cx, text, curses.color_pair(color_id))
        pad = total_w - 1 - (cx - x0)
        if pad > 0:
            _addstr(stdscr, y, cx, " " * pad, curses.color_pair(C_NORMAL))
        _addstr(stdscr, y, x0 + total_w - 1, BOX_V, curses.color_pair(C_GRAY))
        y += 1

    # -- bottom border --
    bottom = BOX_BL + BOX_H * box_w + BOX_BR
    _addstr(stdscr, y, x0, bottom, curses.color_pair(C_GRAY))
    y += 1

    # -- blank line --
    y += 1

    # -- prompt line --
    px = x0
    for text, color_id, bold in PROMPT_SEGMENTS:
        attr = curses.color_pair(color_id)
        if bold:
            attr |= curses.A_BOLD
        px = _addstr(stdscr, y, px, text, attr)
    y += 1

    # -- blank line --
    y += 1

    # -- body text --
    body = BODY_TEXT[:min(len(BODY_TEXT), (w - 2))]
    _addstr(stdscr, y, x0, body, curses.color_pair(C_NORMAL))
    y += 1
    if len(BODY_TEXT) > w - 2:
        _addstr(stdscr, y, x0, BODY_TEXT[w - 2:min(len(BODY_TEXT), 2 * (w - 2))],
                curses.color_pair(C_NORMAL))
        y += 1

    # -- separator --
    y += 1
    sep = BOX_H * min(total_w, w - 2)
    _addstr(stdscr, y, x0, sep, curses.color_pair(C_GRAY))
    y += 1

    return y


# --- Navigation helpers ---

def next_selectable(items, idx, direction=1):
    """Find next selectable item in given direction."""
    i = idx + direction
    while 0 <= i < len(items):
        if items[i]["type"] != ITEM_SEPARATOR:
            return i
        i += direction
    return idx


def find_resume_index(items) -> int | None:
    """Find the first unreviewed item (the resume point)."""
    for i, item in enumerate(items):
        if item["type"] == ITEM_UNREVIEWED:
            return i
    return None


def _find_item(items, name) -> int | None:
    for i, item in enumerate(items):
        if item.get("name") == name:
            return i
    return None


def _clamp_to_selectable(items, idx):
    if not items:
        return 0
    if idx < 0:
        idx = 0
    if idx >= len(items):
        idx = len(items) - 1
    if items[idx]["type"] == ITEM_SEPARATOR:
        fwd = next_selectable(items, idx - 1, 1)
        if fwd != idx - 1:
            return fwd
        return next_selectable(items, idx + 1, -1)
    return idx


def _remove_from_favorites(data, name):
    data["dark"] = [t for t in data["dark"] if t["name"] != name]
    data["light"] = [t for t in data["light"] if t["name"] != name]


# --- Two-column drawing ---

def draw_column(stdscr, items, idx, scroll, resume_idx, col_x, col_w,
                y_start, visible, focused):
    """Draw one column of the theme list."""
    h, w = stdscr.getmaxyx()

    for row in range(visible):
        ti = scroll + row
        y = y_start + row
        if y >= h:
            break
        if ti >= len(items):
            break
        item = items[ti]

        if item["type"] == ITEM_SEPARATOR:
            label = item["label"]
            sep_line = f" {BOX_H*2} {label} {BOX_H * max(1, col_w - len(label) - 6)}"
            sep_line = sep_line[:col_w]
            attr = curses.color_pair(C_GRAY) if focused else curses.color_pair(C_DIM)
            _addstr(stdscr, y, col_x, sep_line, attr)
            continue

        # Gutter marker
        if item["type"] == ITEM_STARRED:
            gutter = " \u2605  "  # star
        elif item["type"] == ITEM_UNREVIEWED and ti == resume_idx:
            gutter = " \u2192  "  # arrow
        else:
            gutter = "    "

        name = item["name"]
        line = f"{gutter}{name}"
        if len(line) > col_w:
            line = line[:col_w - 1]
        else:
            line = line.ljust(col_w)

        if ti == idx and focused:
            _addstr(stdscr, y, col_x, line,
                    curses.color_pair(C_HIGHLIGHT) | curses.A_BOLD)
        elif item["type"] == ITEM_STARRED:
            attr = curses.color_pair(C_YELLOW) if focused else curses.color_pair(C_DIM)
            _addstr(stdscr, y, col_x, line, attr)
        else:
            attr = curses.color_pair(C_NORMAL) if focused else curses.color_pair(C_DIM)
            _addstr(stdscr, y, col_x, line, attr)


# --- Main TUI ---

def main(stdscr, data, unreviewed, classifications, original_theme) -> bool:
    curses.curs_set(0)
    init_colors()

    dark_items = build_items(data, unreviewed, "dark", classifications)
    light_items = build_items(data, unreviewed, "light", classifications)
    columns = [dark_items, light_items]

    if not dark_items and not light_items:
        return False

    # Determine which column the current theme is in
    col = 0  # 0=dark, 1=light
    idx = [0, 0]
    scroll = [0, 0]
    resume_idx = [find_resume_index(dark_items), find_resume_index(light_items)]
    furthest_unreviewed = [-1, -1]

    # Find current theme position
    for c in range(2):
        for i, item in enumerate(columns[c]):
            if item.get("name") == original_theme:
                col = c
                idx[c] = i
                break
        else:
            if columns[c]:
                idx[c] = next_selectable(columns[c], -1, 1)

    def rebuild():
        nonlocal columns, resume_idx
        columns[0] = build_items(data, unreviewed, "dark", classifications)
        columns[1] = build_items(data, unreviewed, "light", classifications)
        resume_idx = [find_resume_index(columns[0]), find_resume_index(columns[1])]

    while True:
        stdscr.clear()
        h, w = stdscr.getmaxyx()

        title = "Pick theme (j/k/^D/^U, h/l=col, Enter=save, Esc=cancel, *=star, x=rm, Space=add)"
        _addstr(stdscr, 0, 0, title[:w - 1], curses.A_BOLD)

        list_start = draw_preview(stdscr, 2, w)

        # Column headers
        col_w = (w - 1) // 2
        divider_x = col_w
        _addstr(stdscr, list_start, 0, "  DARK".ljust(col_w),
                curses.A_BOLD if col == 0 else curses.color_pair(C_DIM))
        _addstr(stdscr, list_start, divider_x, BOX_V, curses.color_pair(C_GRAY))
        _addstr(stdscr, list_start, divider_x + 1, "  LIGHT".ljust(col_w),
                curses.A_BOLD if col == 1 else curses.color_pair(C_DIM))
        list_start += 1

        visible = h - list_start - 1
        if visible < 1:
            visible = 1

        # Update scroll for both columns
        for c in range(2):
            items = columns[c]
            if not items:
                continue
            scroll[c] = max(0, idx[c] - visible // 2)
            scroll[c] = min(scroll[c], max(0, len(items) - visible))

        # Draw left column (dark)
        draw_column(stdscr, columns[0], idx[0], scroll[0], resume_idx[0],
                    0, col_w, list_start, visible, col == 0)

        # Draw divider
        for row in range(visible):
            y = list_start + row
            if y >= h:
                break
            _addstr(stdscr, y, divider_x, BOX_V, curses.color_pair(C_GRAY))

        # Draw right column (light)
        draw_column(stdscr, columns[1], idx[1], scroll[1], resume_idx[1],
                    divider_x + 1, w - divider_x - 1, list_start, visible, col == 1)

        stdscr.refresh()

        # Track unreviewed browsing
        items = columns[col]
        if items and idx[col] < len(items) and items[idx[col]]["type"] == ITEM_UNREVIEWED:
            if idx[col] > furthest_unreviewed[col]:
                furthest_unreviewed[col] = idx[col]

        key = stdscr.getch()

        if key in (ord("q"), 27):  # quit/cancel
            break
        elif key in (curses.KEY_DOWN, ord("j")):
            items = columns[col]
            new_idx = next_selectable(items, idx[col], 1)
            if new_idx != idx[col]:
                idx[col] = new_idx
                set_theme(items[idx[col]]["name"])
        elif key in (curses.KEY_UP, ord("k")):
            items = columns[col]
            new_idx = next_selectable(items, idx[col], -1)
            if new_idx != idx[col]:
                idx[col] = new_idx
                set_theme(items[idx[col]]["name"])
        elif key == 4:  # Ctrl-D: half page down
            items = columns[col]
            half = max(1, visible // 2)
            target = idx[col] + half
            if target >= len(items):
                target = len(items) - 1
            target = _clamp_to_selectable(items, target)
            if target != idx[col]:
                idx[col] = target
                set_theme(items[idx[col]]["name"])
        elif key == 21:  # Ctrl-U: half page up
            items = columns[col]
            half = max(1, visible // 2)
            target = idx[col] - half
            if target < 0:
                target = 0
            target = _clamp_to_selectable(items, target)
            if target != idx[col]:
                idx[col] = target
                set_theme(items[idx[col]]["name"])
        elif key in (curses.KEY_LEFT, ord("h")):
            if col == 1 and columns[0]:
                col = 0
                items = columns[col]
                if items:
                    set_theme(items[idx[col]]["name"])
        elif key in (curses.KEY_RIGHT, ord("l")):
            if col == 0 and columns[1]:
                col = 1
                items = columns[col]
                if items:
                    set_theme(items[idx[col]]["name"])
        elif key in (curses.KEY_ENTER, 10, 13):
            _save_state(data, columns, furthest_unreviewed)
            return True
        elif key == ord("*"):
            items = columns[col]
            if not items:
                continue
            item = items[idx[col]]
            if item["type"] == ITEM_STARRED:
                name = item["name"]
                data["starred"].remove(name)
                rebuild()
                found = _find_item(columns[col], name)
                idx[col] = found if found is not None else _clamp_to_selectable(columns[col], idx[col])
            elif item["type"] == ITEM_FAVORITE:
                name = item["name"]
                data["starred"].append(name)
                rebuild()
                found = _find_item(columns[col], name)
                idx[col] = found if found is not None else _clamp_to_selectable(columns[col], idx[col])
            elif item["type"] == ITEM_UNREVIEWED:
                # Star directly from unreviewed: add to favorites + starred
                name = item["name"]
                info = classify_theme(name)
                if info:
                    entry = {"name": name, "background": info["background"],
                             "bg_color": info["bg_color"]}
                    if info["mode"] == "dark":
                        data["dark"].append(entry)
                    else:
                        data["light"].append(entry)
                    data["starred"].append(name)
                    unreviewed.remove(name)
                    rebuild()
                    found = _find_item(columns[col], name)
                    idx[col] = found if found is not None else _clamp_to_selectable(columns[col], idx[col])
        elif key == ord("x"):
            items = columns[col]
            if not items:
                continue
            item = items[idx[col]]
            if item["type"] == ITEM_STARRED:
                name = item["name"]
                data["starred"].remove(name)
                _remove_from_favorites(data, name)
                rebuild()
                idx[col] = min(idx[col], len(columns[col]) - 1)
                idx[col] = _clamp_to_selectable(columns[col], idx[col])
            elif item["type"] == ITEM_FAVORITE:
                name = item["name"]
                _remove_from_favorites(data, name)
                rebuild()
                idx[col] = min(idx[col], len(columns[col]) - 1)
                idx[col] = _clamp_to_selectable(columns[col], idx[col])
        elif key == ord(" "):
            items = columns[col]
            if not items:
                continue
            item = items[idx[col]]
            if item["type"] == ITEM_UNREVIEWED:
                name = item["name"]
                info = classify_theme(name)
                if info:
                    entry = {"name": name, "background": info["background"],
                             "bg_color": info["bg_color"]}
                    if info["mode"] == "dark":
                        data["dark"].append(entry)
                    else:
                        data["light"].append(entry)
                    unreviewed.remove(name)
                    rebuild()
                    found = _find_item(columns[col], name)
                    if found is not None:
                        idx[col] = found
                    else:
                        idx[col] = min(idx[col], max(0, len(columns[col]) - 1))
                        idx[col] = _clamp_to_selectable(columns[col], idx[col])

    # Cancel: save state but restore original theme
    _save_state(data, columns, furthest_unreviewed)
    return False


def _save_state(data, columns, furthest_unreviewed):
    """Update last_reviewed per column and save yaml."""
    # Find the furthest reviewed theme across both columns
    best_name = None
    best_global_idx = -1
    all_names = ALL_THEMES_FILE.read_text().splitlines() if ALL_THEMES_FILE.exists() else []

    for c in range(2):
        fi = furthest_unreviewed[c]
        if fi >= 0 and fi < len(columns[c]):
            item = columns[c][fi]
            if item["type"] == ITEM_UNREVIEWED:
                try:
                    gi = all_names.index(item["name"])
                    if gi > best_global_idx:
                        best_global_idx = gi
                        best_name = item["name"]
                except ValueError:
                    pass

    if best_name:
        data["review"]["last_reviewed"] = best_name
        data["review"]["reviewed_count"] = best_global_idx + 1

    save_yaml(data)


# --- Entry point ---

def run():
    data = load_yaml()
    last_reviewed = data["review"].get("last_reviewed", "")
    unreviewed = load_unreviewed(last_reviewed)

    # Filter out themes already in favorites or starred
    all_favorite_names = set(
        t["name"] for t in data["dark"]
    ) | set(
        t["name"] for t in data["light"]
    ) | set(data["starred"])
    unreviewed = [n for n in unreviewed if n not in all_favorite_names]

    # Load or generate classifications
    classifications = load_classified()
    if not classifications:
        print("Classification cache not found. Building...")
        classifications = generate_classified()

    if not data["dark"] and not data["light"] and not data["starred"] and not unreviewed:
        print("No themes found.")
        sys.exit(1)

    original_theme = get_current_theme()
    saved = curses.wrapper(main, data, unreviewed, classifications, original_theme)

    if saved:
        final = get_current_theme()
        print(f"Saved: {final}")
    else:
        set_theme(original_theme)
        print(f"Cancelled. Restored: {original_theme}")


if __name__ == "__main__":
    run()

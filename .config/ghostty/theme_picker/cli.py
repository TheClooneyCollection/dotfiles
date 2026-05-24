"""CLI implementation and curses interface for the Ghostty theme picker."""

import curses
import sys
from typing import Any

from theme_picker.core import (
    ITEM_FAVORITE,
    ITEM_SEPARATOR,
    ITEM_STARRED,
    ITEM_UNREVIEWED,
    PickerState,
    action_add_favorite,
    action_move,
    action_page_move,
    action_remove,
    action_star,
    action_switch_column,
    build_items,
    compute_save_state,
    init_state,
    rebuild,
    track_unreviewed,
)
from theme_picker.config import get_current_theme, reload_config, set_theme
from theme_picker.data import (
    ALL_THEMES_FILE,
    classify,
    classify_theme,
    generate_classified,
    load_classified,
    load_unreviewed,
    load_yaml,
    luminance,
    parse_bg,
    save_yaml,
)

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


def _addstr(stdscr: Any, y: int, x: int, text: str, attr: int = 0) -> int:
    """Safe addstr that avoids writing to the bottom-right corner."""
    h, w = stdscr.getmaxyx()
    if y >= h or x >= w:
        return x + len(text)
    maxlen = w - x - 1 if y == h - 1 else w - x
    if maxlen <= 0:
        return x + len(text)
    stdscr.addnstr(y, x, text, maxlen, attr)
    return x + len(text)


def draw_preview(stdscr: Any, y: int, w: int) -> int:
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


def draw_column(stdscr: Any, items: list[dict], idx: int, scroll: int, resume_idx: int | None,
                col_x: int, col_w: int, y_start: int, visible: int, focused: bool) -> None:
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


def main_tui(stdscr: Any, data: dict, unreviewed: list[str],
             classifications: dict[str, str], original_theme: str) -> bool:
    curses.curs_set(0)
    init_colors()

    # Initialize Pure State
    state = init_state(
        data=data,
        unreviewed=unreviewed,
        classifications=classifications,
        original_theme=original_theme,
        classify_fn=classify_theme,
    )

    if not state.columns[0] and not state.columns[1]:
        return False

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
                curses.A_BOLD if state.col == 0 else curses.color_pair(C_DIM))
        _addstr(stdscr, list_start, divider_x, BOX_V, curses.color_pair(C_GRAY))
        _addstr(stdscr, list_start, divider_x + 1, "  LIGHT".ljust(col_w),
                curses.A_BOLD if state.col == 1 else curses.color_pair(C_DIM))
        list_start += 1

        visible = h - list_start - 1
        if visible < 1:
            visible = 1

        # Update scroll for both columns
        for c in range(2):
            items = state.columns[c]
            if not items:
                continue
            state.scroll[c] = max(0, state.idx[c] - visible // 2)
            state.scroll[c] = min(state.scroll[c], max(0, len(items) - visible))

        # Dynamic resume index calculation
        from theme_picker.core import find_resume_index
        resume_idx = [find_resume_index(state.columns[0]), find_resume_index(state.columns[1])]

        # Draw left column (dark)
        draw_column(stdscr, state.columns[0], state.idx[0], state.scroll[0], resume_idx[0],
                    0, col_w, list_start, visible, state.col == 0)

        # Draw divider
        for row in range(visible):
            y = list_start + row
            if y >= h:
                break
            _addstr(stdscr, y, divider_x, BOX_V, curses.color_pair(C_GRAY))

        # Draw right column (light)
        draw_column(stdscr, state.columns[1], state.idx[1], state.scroll[1], resume_idx[1],
                    divider_x + 1, w - divider_x - 1, list_start, visible, state.col == 1)

        stdscr.refresh()

        # Track furthest unreviewed browsing
        state = track_unreviewed(state)

        key = stdscr.getch()

        if key in (ord("q"), 27):  # quit/cancel
            break
        elif key in (curses.KEY_DOWN, ord("j")):
            state, preview = action_move(state, 1)
            if preview:
                set_theme(preview)
        elif key in (curses.KEY_UP, ord("k")):
            state, preview = action_move(state, -1)
            if preview:
                set_theme(preview)
        elif key == 4:  # Ctrl-D: half page down
            state, preview = action_page_move(state, 1, visible)
            if preview:
                set_theme(preview)
        elif key == 21:  # Ctrl-U: half page up
            state, preview = action_page_move(state, -1, visible)
            if preview:
                set_theme(preview)
        elif key in (curses.KEY_LEFT, ord("h")):
            state, preview = action_switch_column(state, -1)
            if preview:
                set_theme(preview)
        elif key in (curses.KEY_RIGHT, ord("l")):
            state, preview = action_switch_column(state, 1)
            if preview:
                set_theme(preview)
        elif key in (curses.KEY_ENTER, 10, 13):
            all_theme_names = ALL_THEMES_FILE.read_text().splitlines() if ALL_THEMES_FILE.exists() else []
            data = compute_save_state(state, all_theme_names)
            save_yaml(data)
            return True
        elif key == ord("*"):
            state, _ = action_star(state, classify_theme)
            items = state.columns[state.col]
            if items and state.idx[state.col] < len(items):
                set_theme(items[state.idx[state.col]]["name"])
        elif key == ord("x"):
            state, _ = action_remove(state, classify_theme)
            items = state.columns[state.col]
            if items and state.idx[state.col] < len(items):
                set_theme(items[state.idx[state.col]]["name"])
        elif key == ord(" "):
            state, _ = action_add_favorite(state, classify_theme)
            items = state.columns[state.col]
            if items and state.idx[state.col] < len(items):
                set_theme(items[state.idx[state.col]]["name"])

    # Cancel: save state but restore original theme
    all_theme_names = ALL_THEMES_FILE.read_text().splitlines() if ALL_THEMES_FILE.exists() else []
    data = compute_save_state(state, all_theme_names)
    save_yaml(data)
    return False


def run() -> None:
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
    saved = curses.wrapper(main_tui, data, unreviewed, classifications, original_theme)

    if saved:
        final = get_current_theme()
        print(f"Saved: {final}")
    else:
        set_theme(original_theme)
        print(f"Cancelled. Restored: {original_theme}")


def main() -> None:
    try:
        run()
    except KeyboardInterrupt:
        print("\nExited.")
        sys.exit(0)

if __name__ == "__main__":
    raise SystemExit(main())

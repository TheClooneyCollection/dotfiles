"""Theme data I/O, classification, and path constants for the Ghostty theme picker."""

import re
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent.parent
YAML_FILE = SCRIPT_DIR / "themes.yaml"
ALL_THEMES_FILE = SCRIPT_DIR / "all-themes.txt"
CLASSIFIED_FILE = SCRIPT_DIR / "classified-themes.yaml"
THEMES_DIR = Path("/Applications/Ghostty.app/Contents/Resources/ghostty/themes")


def load_classified() -> dict[str, str]:
    """Load classified-themes.yaml, returns dict of name -> mode."""
    if not CLASSIFIED_FILE.exists():
        return {}
    result = {}
    for line in CLASSIFIED_FILE.read_text().splitlines():
        if line.startswith("#") or not line.strip():
            continue
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
    print()

    out_lines = ["# Auto-generated. Maps theme name -> mode."]
    for name in sorted(classified.keys(), key=str.lower):
        out_lines.append(f"{name}: {classified[name]}")
    out_lines.append("")
    CLASSIFIED_FILE.write_text("\n".join(out_lines))
    return classified


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

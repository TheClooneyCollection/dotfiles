"""Ghostty configuration management — read, write, and reload the active theme."""

import os
import re
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent.parent
CONFIG = SCRIPT_DIR / "config"


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

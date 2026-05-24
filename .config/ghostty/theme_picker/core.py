"""Pure functional core for the Ghostty theme picker — state transitions with no side effects."""

from dataclasses import dataclass, field
from typing import Callable

# ── Item type constants ──────────────────────────────────────────────

ITEM_STARRED = "starred"
ITEM_FAVORITE = "favorite"
ITEM_UNREVIEWED = "unreviewed"
ITEM_SEPARATOR = "separator"

# ── State ────────────────────────────────────────────────────────────


@dataclass
class PickerState:
    """All mutable state for the theme picker TUI."""
    data: dict                                     # {review, starred, dark, light}
    unreviewed: list[str]                           # unreviewed theme names
    classifications: dict[str, str]                 # name -> "dark"/"light"
    col: int = 0                                    # 0=dark, 1=light
    idx: list[int] = field(default_factory=lambda: [0, 0])
    scroll: list[int] = field(default_factory=lambda: [0, 0])
    furthest_unreviewed: list[int] = field(default_factory=lambda: [-1, -1])
    columns: list[list[dict]] = field(default_factory=lambda: [[], []])


# ── Pure helper functions ────────────────────────────────────────────


def build_items(data: dict, unreviewed: list[str], mode: str,
                classifications: dict[str, str],
                classify_fn: Callable | None = None) -> list[dict]:
    """Build display list for one column (dark or light)."""
    items = []

    # Starred section (filtered to this mode)
    for name in data["starred"]:
        theme_mode = classifications.get(name)
        if theme_mode is None and classify_fn is not None:
            info = classify_fn(name)
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


# ── Rebuild ──────────────────────────────────────────────────────────


def rebuild(state: PickerState,
            classify_fn: Callable | None = None) -> PickerState:
    """Rebuild columns from current state data."""
    state.columns[0] = build_items(
        state.data, state.unreviewed, "dark",
        state.classifications, classify_fn)
    state.columns[1] = build_items(
        state.data, state.unreviewed, "light",
        state.classifications, classify_fn)
    return state


# ── Action functions ─────────────────────────────────────────────────


def action_move(state: PickerState, direction: int) -> tuple[PickerState, str | None]:
    """Move cursor up (direction=-1) or down (direction=1)."""
    items = state.columns[state.col]
    if not items:
        return state, None
    new_idx = next_selectable(items, state.idx[state.col], direction)
    if new_idx != state.idx[state.col]:
        state.idx[state.col] = new_idx
        return state, items[new_idx]["name"]
    return state, None


def action_page_move(state: PickerState, direction: int,
                     visible: int) -> tuple[PickerState, str | None]:
    """Move cursor by half a page."""
    items = state.columns[state.col]
    if not items:
        return state, None
    half = max(1, visible // 2)
    target = state.idx[state.col] + (half * direction)
    target = max(0, min(target, len(items) - 1))
    target = _clamp_to_selectable(items, target)
    if target != state.idx[state.col]:
        state.idx[state.col] = target
        return state, items[target]["name"]
    return state, None


def action_switch_column(state: PickerState,
                         direction: int) -> tuple[PickerState, str | None]:
    """Switch to other column. direction: -1=left, 1=right."""
    new_col = state.col + direction
    if new_col < 0 or new_col > 1:
        return state, None
    if not state.columns[new_col]:
        return state, None
    state.col = new_col
    items = state.columns[state.col]
    if items:
        return state, items[state.idx[state.col]]["name"]
    return state, None


def action_star(state: PickerState,
                classify_fn: Callable) -> tuple[PickerState, str | None]:
    """Toggle star on current item, or star directly from unreviewed."""
    items = state.columns[state.col]
    if not items:
        return state, None
    item = items[state.idx[state.col]]

    if item["type"] == ITEM_STARRED:
        # Unstar: remove from starred list
        name = item["name"]
        state.data["starred"].remove(name)
        state = rebuild(state, classify_fn)
        found = _find_item(state.columns[state.col], name)
        state.idx[state.col] = (
            found if found is not None
            else _clamp_to_selectable(state.columns[state.col], state.idx[state.col])
        )

    elif item["type"] == ITEM_FAVORITE:
        # Star a favorite
        name = item["name"]
        state.data["starred"].append(name)
        state = rebuild(state, classify_fn)
        found = _find_item(state.columns[state.col], name)
        state.idx[state.col] = (
            found if found is not None
            else _clamp_to_selectable(state.columns[state.col], state.idx[state.col])
        )

    elif item["type"] == ITEM_UNREVIEWED:
        # Star from unreviewed: add to favorites + starred
        name = item["name"]
        info = classify_fn(name)
        if info:
            entry = {"name": name, "background": info["background"],
                     "bg_color": info["bg_color"]}
            if info["mode"] == "dark":
                state.data["dark"].append(entry)
            else:
                state.data["light"].append(entry)
            state.data["starred"].append(name)
            state.unreviewed.remove(name)
            state = rebuild(state, classify_fn)
            found = _find_item(state.columns[state.col], name)
            state.idx[state.col] = (
                found if found is not None
                else _clamp_to_selectable(state.columns[state.col], state.idx[state.col])
            )

    return state, None


def action_remove(state: PickerState,
                  classify_fn: Callable | None = None) -> tuple[PickerState, str | None]:
    """Remove current item from favorites/starred."""
    items = state.columns[state.col]
    if not items:
        return state, None
    item = items[state.idx[state.col]]

    if item["type"] == ITEM_STARRED:
        name = item["name"]
        state.data["starred"].remove(name)
        _remove_from_favorites(state.data, name)
        state = rebuild(state, classify_fn)
        state.idx[state.col] = min(state.idx[state.col], len(state.columns[state.col]) - 1)
        state.idx[state.col] = _clamp_to_selectable(state.columns[state.col], state.idx[state.col])

    elif item["type"] == ITEM_FAVORITE:
        name = item["name"]
        _remove_from_favorites(state.data, name)
        state = rebuild(state, classify_fn)
        state.idx[state.col] = min(state.idx[state.col], len(state.columns[state.col]) - 1)
        state.idx[state.col] = _clamp_to_selectable(state.columns[state.col], state.idx[state.col])

    return state, None


def action_add_favorite(state: PickerState,
                        classify_fn: Callable) -> tuple[PickerState, str | None]:
    """Add unreviewed theme to favorites (Space key)."""
    items = state.columns[state.col]
    if not items:
        return state, None
    item = items[state.idx[state.col]]

    if item["type"] != ITEM_UNREVIEWED:
        return state, None

    name = item["name"]
    info = classify_fn(name)
    if info:
        entry = {"name": name, "background": info["background"],
                 "bg_color": info["bg_color"]}
        if info["mode"] == "dark":
            state.data["dark"].append(entry)
        else:
            state.data["light"].append(entry)
        state.unreviewed.remove(name)
        state = rebuild(state, classify_fn)
        found = _find_item(state.columns[state.col], name)
        if found is not None:
            state.idx[state.col] = found
        else:
            state.idx[state.col] = min(state.idx[state.col], max(0, len(state.columns[state.col]) - 1))
            state.idx[state.col] = _clamp_to_selectable(state.columns[state.col], state.idx[state.col])

    return state, None


# ── Save / tracking / init ───────────────────────────────────────────


def compute_save_state(state: PickerState,
                       all_theme_names: list[str]) -> dict:
    """Update review progress in data based on furthest_unreviewed. Pure."""
    best_name = None
    best_global_idx = -1

    for c in range(2):
        fi = state.furthest_unreviewed[c]
        if fi >= 0 and fi < len(state.columns[c]):
            item = state.columns[c][fi]
            if item["type"] == ITEM_UNREVIEWED:
                try:
                    gi = all_theme_names.index(item["name"])
                    if gi > best_global_idx:
                        best_global_idx = gi
                        best_name = item["name"]
                except ValueError:
                    pass

    if best_name:
        state.data["review"]["last_reviewed"] = best_name
        state.data["review"]["reviewed_count"] = best_global_idx + 1

    return state.data


def track_unreviewed(state: PickerState) -> PickerState:
    """Update furthest_unreviewed tracking for the current position."""
    items = state.columns[state.col]
    if items and state.idx[state.col] < len(items):
        if items[state.idx[state.col]]["type"] == ITEM_UNREVIEWED:
            if state.idx[state.col] > state.furthest_unreviewed[state.col]:
                state.furthest_unreviewed[state.col] = state.idx[state.col]
    return state


def init_state(data: dict, unreviewed: list[str],
               classifications: dict[str, str],
               original_theme: str,
               classify_fn: Callable | None = None) -> PickerState:
    """Create and initialize a PickerState for the given data."""
    state = PickerState(
        data=data,
        unreviewed=unreviewed,
        classifications=classifications,
    )
    state = rebuild(state, classify_fn)

    if not state.columns[0] and not state.columns[1]:
        return state

    # Find current theme position
    for c in range(2):
        for i, item in enumerate(state.columns[c]):
            if item.get("name") == original_theme:
                state.col = c
                state.idx[c] = i
                break
        else:
            if state.columns[c]:
                state.idx[c] = next_selectable(state.columns[c], -1, 1)

    return state

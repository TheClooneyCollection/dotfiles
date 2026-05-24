"""Unit tests for the theme_picker.core functional core."""

import pytest
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
    next_selectable,
    rebuild,
    track_unreviewed,
)

# Mock classify_fn that returns predictable outputs
def mock_classify_theme(name: str) -> dict:
    mode = "light" if "light" in name.lower() or "white" in name.lower() else "dark"
    return {
        "name": name,
        "mode": mode,
        "background": "#ffffff" if mode == "light" else "#000000",
        "bg_color": "white" if mode == "light" else "black",
    }


@pytest.fixture
def sample_data():
    return {
        "review": {
            "last_reviewed": "",
            "reviewed_count": 0,
            "total_count": 5,
        },
        "starred": ["One Dark"],
        "dark": [
            {"name": "One Dark", "background": "#282c34", "bg_color": "dark gray"},
            {"name": "Dracula", "background": "#282a36", "bg_color": "black"},
        ],
        "light": [
            {"name": "Solarized Light", "background": "#fdf6e3", "bg_color": "cream"},
        ],
    }


@pytest.fixture
def sample_unreviewed():
    return ["Gruvbox Dark", "Gruvbox Light", "Nord"]


@pytest.fixture
def sample_classifications():
    return {
        "One Dark": "dark",
        "Dracula": "dark",
        "Solarized Light": "light",
        "Gruvbox Dark": "dark",
        "Gruvbox Light": "light",
        "Nord": "dark",
    }


# ── Test Categories ──────────────────────────────────────────────────

def test_build_items(sample_data, sample_unreviewed, sample_classifications):
    # Dark Mode
    dark_items = build_items(
        data=sample_data,
        unreviewed=sample_unreviewed,
        mode="dark",
        classifications=sample_classifications,
        classify_fn=mock_classify_theme,
    )
    # One Dark is starred, Dracula is favorite, Gruvbox Dark and Nord are unreviewed
    assert len(dark_items) == 6
    assert dark_items[0] == {"type": ITEM_STARRED, "name": "One Dark"}
    assert dark_items[1] == {"type": ITEM_SEPARATOR, "label": "favorites"}
    assert dark_items[2] == {"type": ITEM_FAVORITE, "name": "Dracula", "bg_color": "black"}
    assert dark_items[3] == {"type": ITEM_SEPARATOR, "label": "unreviewed"}
    assert dark_items[4] == {"type": ITEM_UNREVIEWED, "name": "Gruvbox Dark"}
    assert dark_items[5] == {"type": ITEM_UNREVIEWED, "name": "Nord"}

    # Light Mode
    light_items = build_items(
        data=sample_data,
        unreviewed=sample_unreviewed,
        mode="light",
        classifications=sample_classifications,
        classify_fn=mock_classify_theme,
    )
    # Solarized Light is favorite (no starred lights), Gruvbox Light is unreviewed
    assert len(light_items) == 3
    assert light_items[0] == {"type": ITEM_FAVORITE, "name": "Solarized Light", "bg_color": "cream"}
    assert light_items[1] == {"type": ITEM_SEPARATOR, "label": "unreviewed"}
    assert light_items[2] == {"type": ITEM_UNREVIEWED, "name": "Gruvbox Light"}


def test_next_selectable(sample_data, sample_unreviewed, sample_classifications):
    items = build_items(sample_data, sample_unreviewed, "dark", sample_classifications, mock_classify_theme)
    # items list:
    # 0: Starred "One Dark"
    # 1: Separator "favorites"
    # 2: Favorite "Dracula"
    # 3: Separator "unreviewed"
    # 4: Unreviewed "Gruvbox Dark"
    
    # Check skipped separator going down
    assert next_selectable(items, 0, 1) == 2  # skips index 1
    # Check skipped separator going up
    assert next_selectable(items, 2, -1) == 0  # skips index 1
    # Check boundary down
    assert next_selectable(items, 5, 1) == 5
    # Check boundary up
    assert next_selectable(items, 0, -1) == 0


def test_action_star_unstar(sample_data, sample_unreviewed, sample_classifications):
    # Setup initial state
    state = init_state(sample_data, sample_unreviewed, sample_classifications, "Dracula", mock_classify_theme)
    
    # 1. Star Dracula (current is index 2, which is Dracula in dark column)
    assert state.columns[0][state.idx[0]]["name"] == "Dracula"
    state, preview = action_star(state, mock_classify_theme)
    
    # Dracula should now be in starred
    assert "Dracula" in state.data["starred"]
    # Rebuild will update items, Dracula is starred now
    starred_items = [i for i in state.columns[0] if i["type"] == ITEM_STARRED]
    assert len(starred_items) == 2
    assert {"type": ITEM_STARRED, "name": "Dracula"} in starred_items

    # 2. Unstar Dracula (which is now at index 1 of the rebuilt column)
    state.idx[0] = next(i for i, x in enumerate(state.columns[0]) if x.get("name") == "Dracula")
    state, preview = action_star(state, mock_classify_theme)
    assert "Dracula" not in state.data["starred"]


def test_action_star_from_unreviewed(sample_data, sample_unreviewed, sample_classifications):
    state = init_state(sample_data, sample_unreviewed, sample_classifications, "Gruvbox Dark", mock_classify_theme)
    # Gruvbox Dark is unreviewed. Let's star it.
    assert state.columns[0][state.idx[0]]["name"] == "Gruvbox Dark"
    state, preview = action_star(state, mock_classify_theme)
    
    assert "Gruvbox Dark" in state.data["starred"]
    assert "Gruvbox Dark" not in state.unreviewed
    assert any(x["name"] == "Gruvbox Dark" for x in state.data["dark"])


def test_action_remove(sample_data, sample_unreviewed, sample_classifications):
    state = init_state(sample_data, sample_unreviewed, sample_classifications, "Dracula", mock_classify_theme)
    # Dracula is favorite
    state, preview = action_remove(state, mock_classify_theme)
    assert not any(x["name"] == "Dracula" for x in state.data["dark"])
    
    # Remove starred item
    state = init_state(sample_data, sample_unreviewed, sample_classifications, "One Dark", mock_classify_theme)
    state, preview = action_remove(state, mock_classify_theme)
    assert "One Dark" not in state.data["starred"]
    assert not any(x["name"] == "One Dark" for x in state.data["dark"])


def test_action_add_favorite(sample_data, sample_unreviewed, sample_classifications):
    state = init_state(sample_data, sample_unreviewed, sample_classifications, "Gruvbox Dark", mock_classify_theme)
    # Gruvbox Dark is unreviewed
    state, preview = action_add_favorite(state, mock_classify_theme)
    
    assert "Gruvbox Dark" not in state.unreviewed
    assert any(x["name"] == "Gruvbox Dark" for x in state.data["dark"])
    assert "Gruvbox Dark" not in state.data["starred"]


def test_action_move(sample_data, sample_unreviewed, sample_classifications):
    state = init_state(sample_data, sample_unreviewed, sample_classifications, "One Dark", mock_classify_theme)
    # Index 0 is One Dark. Move down.
    state, preview = action_move(state, 1)
    assert state.idx[0] == 2  # Skips separator at index 1
    assert preview == "Dracula"


def test_action_switch_column(sample_data, sample_unreviewed, sample_classifications):
    state = init_state(sample_data, sample_unreviewed, sample_classifications, "One Dark", mock_classify_theme)
    assert state.col == 0 # Dark
    state, preview = action_switch_column(state, 1) # Switch right
    assert state.col == 1 # Light
    assert preview == "Solarized Light"


def test_action_page_move(sample_data, sample_unreviewed, sample_classifications):
    state = init_state(sample_data, sample_unreviewed, sample_classifications, "One Dark", mock_classify_theme)
    # 5 items in dark column. Move down by 4 (half visible height of say 8).
    state, preview = action_page_move(state, 1, 8)
    assert state.idx[0] == 4  # Clamps to last selectable (Gruvbox Dark)
    assert preview == "Gruvbox Dark"


def test_save_state_and_tracking(sample_data, sample_unreviewed, sample_classifications):
    state = init_state(sample_data, sample_unreviewed, sample_classifications, "Gruvbox Dark", mock_classify_theme)
    # Initial furthest unreviewed
    assert state.furthest_unreviewed[0] == -1
    
    # Track position
    state = track_unreviewed(state)
    assert state.furthest_unreviewed[0] == state.idx[0]
    
    # Compute save state
    all_names = ["One Dark", "Dracula", "Solarized Light", "Gruvbox Dark", "Nord"]
    data = compute_save_state(state, all_names)
    assert data["review"]["last_reviewed"] == "Gruvbox Dark"
    assert data["review"]["reviewed_count"] == 4 # Gruvbox Dark is 4th in all_names (1-indexed)


def test_init_state(sample_data, sample_unreviewed, sample_classifications):
    # Initialize with Dracula (dark theme)
    state = init_state(sample_data, sample_unreviewed, sample_classifications, "Dracula", mock_classify_theme)
    assert state.col == 0
    assert state.columns[0][state.idx[0]]["name"] == "Dracula"

    # Initialize with Solarized Light (light theme)
    state2 = init_state(sample_data, sample_unreviewed, sample_classifications, "Solarized Light", mock_classify_theme)
    assert state2.col == 1
    assert state2.columns[1][state2.idx[1]]["name"] == "Solarized Light"

# Ghostty Config

## Files

- **config** - main Ghostty config (hot-reloads on save)
- **themes.yaml** - picked themes tagged light/dark with bg color labels and review progress
- **all-themes.txt** - snapshot of all available theme names for diffing future Ghostty updates
- **generate-themes-yaml.py** - regenerates themes.yaml from the picked list
- **pick-theme.py** - TUI for browsing and applying picked themes

## Theme Picker

```
python3 pick-theme.py          # all picks
python3 pick-theme.py dark     # dark only
python3 pick-theme.py light    # light only
```

- Arrow keys or `j`/`k` to navigate
- Theme applies live as you move (sends SIGUSR2 to reload Ghostty's config)
- `Enter` to confirm and quit
- `Esc` or `q` to cancel and restore the previous theme

## Adding Themes

1. Edit `PICKED_THEMES` and `LAST_REVIEWED` in `generate-themes-yaml.py`
2. Run `python3 generate-themes-yaml.py` to regenerate `themes.yaml`

## Checking for New Themes

After a Ghostty update, diff the bundled themes against the snapshot:

```
diff <(ls /Applications/Ghostty.app/Contents/Resources/ghostty/themes/) all-themes.txt
```

New entries are themes added since your last review. Update `all-themes.txt` after reviewing.

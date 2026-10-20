# Window picker

Press `prefix prefix` (normally `Ctrl-b Ctrl-b`) to browse visible sessions.
The picker starts in MRU order: most recently visited windows first, with the
current window last. Press `Ctrl-s` to toggle between MRU and the original
session/window order. Typing filters either list, Enter switches, and Escape
cancels. The active pane preview and grouped-session deduplication are retained.

Visits are recorded by stable window ID in the tmux window option
`@window_picker_visit`, shared across clients on that server. Renaming or
renumbering windows preserves their history. History lasts until the window or
server is destroyed; no history file is written. Unvisited windows retain their
original order. Detached and `agents-*` sessions do not record visits, and opening
the popup does not count as a visit. The ordering is a snapshot when opened.

After updating, reload with `prefix r` (or `tmux source-file ~/.tmux.conf`).
Visit a few windows to populate history; past visits cannot be reconstructed.
Dependencies: tmux, fzf with `transform` bindings, Bash, Python 3, and standard
Unix utilities. Indexed hooks `[719]` coexist with the tmux-agents hooks.

Run regression checks from the repository root:

```sh
bash -n .bin/tmux-window-picker
python3 .bin/tests/test-tmux-window-picker.py
```

The integration test creates a randomly named private tmux server, attaches a
PTY client, and shuts down only that server. It exercises real visit hooks,
cross-session ordering, hidden/detached filtering, stable IDs, popup behavior,
grouped sessions, both fzf reload commands, preview capture and switching.

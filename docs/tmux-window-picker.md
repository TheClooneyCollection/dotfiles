# Window picker

Press `prefix prefix` (normally `Ctrl-b Ctrl-b`) to browse visible sessions.
The picker starts in `Frequent` order: historical visit frequency weighted
by recency. Each visit adds one point; points have a 15-minute half-life.
Eight visits 15 minutes ago have the same weight as four visits now. Visits to
the same window within one minute are coalesced, including duplicate hooks.
The current window follows the same rules as every other window, so it is
usually on top; the cursor therefore starts on the second row, which is
normally the window you want to flip back to. Equal scores use the original
session/window order, without a last-visited tie-breaker.

Press `Ctrl-s` to toggle between Frequent and the original session/window order.
Typing filters either list, Enter switches, and Escape cancels. The active pane
preview and grouped-session deduplication are retained. Opening the picker does
not change scores; the ordering is a snapshot when opened. Small score changes
can still move similarly ranked windows, especially while history is sparse.

On a counted visit, only that window is updated:
`new_score = old_score * 0.5^(elapsed_seconds / 900) + 1`.
Opening the picker compares all scores decayed to the current time, without
writing back or adding visits. Sorting uses logarithms of the decayed scores
so very small values retain their relative order after hours or days of idle
time. Fifteen minutes is a half-life, not an expiry: inactivity alone does not
reset the ordering. Windows with history rank ahead of never-visited windows.

Scores and update times are recorded by stable window ID in the tmux window
option `@window_picker_score`, shared across clients on that server. Renaming or
renumbering windows preserves history. History lasts until the window or server
is destroyed; no history file is written. Detached and `agents-*` sessions do
not record visits. Existing `@window_picker_visit` timestamps count as one
historical visit each; earlier visit counts cannot be reconstructed.

Existing hooks use the updated script immediately; close and reopen the picker
to use the new ordering. For a fresh setup, load the hooks with `prefix r`
(or `tmux source-file ~/.tmux.conf`). History builds as you use your windows.
Dependencies: tmux, fzf with `transform` bindings, Bash, Python 3, and standard
Unix utilities. Indexed hooks `[719]` coexist with the tmux-agents hooks.

Run regression checks from the repository root:

```sh
bash -n .bin/tmux-window-picker
python3 .bin/tests/test-tmux-window-picker.py
```

The integration test creates a randomly named private tmux server, attaches a
PTY client, and shuts down only that server. It exercises real visit hooks,
decay, rapid-revisit coalescing, current-window neutrality, cross-session ordering, hidden/detached filtering, stable IDs, popup behavior,
grouped sessions, both fzf reload commands, preview capture and switching.

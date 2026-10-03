# A reopened sub agent comes back in a hidden window

**Decision.** `tmux-spawn --resume` (and Enter on a closed agent in the list) reopens a sub agent in a hidden window of `agents-<project>`, even if it used to be a split. To put it back in a layout, reopen it and move the pane, or spawn anew with `--split`.

**Why.** The pane it split from may be gone, and the layout may have changed since; putting a pane back into someone's window unasked is more surprising than a hidden window one keystroke away.

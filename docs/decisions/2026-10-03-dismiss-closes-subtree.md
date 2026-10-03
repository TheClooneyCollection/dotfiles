# Closing an agent closes its sub agents too

**Decision.** `tmux-dismiss` closes the agent and its whole subtree, deepest first, and lists every agent it closed. Each one keeps its session record, so any of them can be reopened with `tmux-spawn --resume`. So "close the secondary and the worker" is `tmux-dismiss --from <main> secondary`.

`--done` (close finished sub agents) only closes an agent whose whole subtree is done or exited; one with a working or waiting descendant is skipped, with a note saying why. Closing a finished parent shouldn't kill work still in progress below it.

**Why.** A sub agent left behind by its closed parent has nobody to report to; closing a piece of work should close all of it.

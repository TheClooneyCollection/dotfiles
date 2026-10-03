# Sub agents can open in a visible split

**Context.** For the agent chain the user wants everyone in one window: main on the left half, the secondary top right, the worker bottom right. `tmux-spawn` always opened sub agents in a hidden window of `agents-<project>`.

**Decision.** `tmux-spawn --split <pane> [--right | --below] [--size N%]` opens the sub agent as a split of `<pane>` (a name or pane id) instead of a hidden window: `--right` (the default) splits it left and right, `--below` top and bottom, and `--size` is the new pane's share (default 50%). It combines with `--for`, so the chain is:

```
tmux-spawn claude --from main --split main --right --name secondary ...
tmux-spawn codex-2nd --from main --for secondary --split secondary --below --name worker ...
```

Everything else is unchanged: it is still a sub agent (in the agent list and the chip, with its owner, depth and session record), `tmux-dismiss` closes its pane, and its transcript stays after it exits, set on the pane only so the rest of the window isn't affected.

**Why.** One flag picks where, and the direction words read like tmux's own. A hidden window stays the default because most sub agents are meant to be out of the way.

**Rejected.** `--right-of <pane>` / `--below <pane>` as two flags: two ways to name the target for one idea.

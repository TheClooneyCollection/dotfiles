# --keep-children leaves the children unowned

**Decision.** `tmux-dismiss --keep-children` closes only the named agent. Its direct sub agents lose their parent: their `@parent` is cleared and their link to the closed agent goes with its pane, like a reopened agent whose parent is gone. They no longer count as sub agents, so the agent list's "agents" view drops them; they're still in its "all" view (`ctrl-a`), and the user can close them with `tmux-dismiss`. Their own sub agents stay theirs.

**Why.** Pointing them at a pane that no longer exists would break replies and ownership checks; handing them to the grandparent silently would give it agents it never asked for.

# An agent can close any of its descendants

**Context.** A main agent tried to close the worker of its agent chain and was refused: the worker was spawned with `--for secondary`, so its parent is the secondary, and `tmux-dismiss --from` only allowed direct sub agents.

**Decision.** `tmux-dismiss --from ME <name>` closes `<name>` if `ME` is anywhere up its parent chain. Agents above you and unrelated agents are still refused. There's no separate "whoever spawned it may close it" rule: the descendant rule already covers the chain, since the worker's owner (the secondary) is main's sub agent.

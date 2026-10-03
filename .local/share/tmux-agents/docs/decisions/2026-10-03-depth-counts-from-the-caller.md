# Its depth counts from the agent that spawned it

**Decision.** A sub agent spawned with `--for` gets the depth of the agent that ran `tmux-spawn`, plus one, not its owner's. A worker main (depth 0) spawns for its coordinator is at depth 1, so it can still start its own sub agents.

**Why.** That's the point of `--for`. It changes who owns the agent, not how deep anyone may go: the depth limit still applies to whoever runs `tmux-spawn`, so `--for` can't be used to spawn deeper than the caller could anyway.

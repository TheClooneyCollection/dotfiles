# An agent can spawn a sub agent for another agent

**Context.** In an agent chain (main → coordinator → worker), the worker works for the coordinator. If the coordinator spawned it, the worker would sit at depth 2 and couldn't start sub agents of its own (see [the depth limit](2026-10-03-depth-limit-stays-2.md)). So main spawns it, but a normal spawn makes it main's sub agent.

**Decision.** `tmux-spawn --for <owner>` spawns a sub agent that belongs to `<owner>`: its parent is `<owner>`, it shows under `<owner>` in the agent list, it reports to `<owner>`, and `<owner>` closes it. `<owner>` must already be connected to the caller, so an agent can't hand sub agents to agents it doesn't work with.

**Rejected.** Spawning normally and then disconnecting main: main would stay the parent, so replies, the list and cleanup would still point at main.

# The spawn depth limit stays at 2

**Context.** `TMUX_AGENTS_MAX_DEPTH` (default 2): an agent you start is at depth 0, and only agents below depth 2 can spawn. The agent chain ran into it.

**Decision.** Keep the default at 2 and solve the agent chain with [`--for`](2026-10-03-spawn-for-another-agent.md) instead. The limit stays configurable.

**Why.** Not measured; a conservative default. Each level multiplies agents, tokens and cost, adds relay latency and lost context, and moves the user further from the agents doing the work. Two levels let an agent split work, and its sub agents split once more.

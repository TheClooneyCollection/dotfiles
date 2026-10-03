# A sub agent spawned for another agent isn't connected to the caller

**Decision.** With `tmux-spawn --for <owner>`, the new agent is connected to `<owner>` only. The caller (main) and the worker have no link.

**Why.** The worker should take work from, and report to, the agent it works for. A link to main would invite main to bypass the coordinator.

# Its first message comes from its owner

**Decision.** A sub agent spawned with `--for` starts without a task. The caller tells the owner that the new agent is now connected to it, passing along any brief it has. The owner introduces itself to the new agent and sends it its first task.

**Why.** The worker should begin its relationship with the agent it works for, and hear its first task from it, not from main.

**Rejected.** The caller sending the first task, with reply instructions pointing at the owner.

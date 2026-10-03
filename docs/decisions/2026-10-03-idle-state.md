# A sub agent with no task yet shows as idle

**Context.** A worker spawned with `--for`, still waiting for its owner's first task, showed as "working" in the list and the chip: `tmux-spawn` never set its state, and anything that isn't needs-you or done was shown as working.

**Decision.** A new state, `idle`, shown as `○ idle` (grey). A sub agent spawned without a task (with `--for`, or with no task text) starts idle; the first request it gets makes it working, as any request does. At the end of a turn, idle is treated like done: nobody is waiting for a reply from it, so it isn't flagged as needing the user. A progress report from an idle agent means it started on something (say, the user asked it directly), so it becomes working.

**Why.** "Working" for an agent that has nothing to do misleads the user about where work is happening; "done" would claim it finished something it never started.

# Product decisions

Decisions the user made about how tmux-agents behaves, one per file, so later changes don't undo them by accident. Technical details live in [DESIGN.md](../../DESIGN.md) and [docs/design](../design/).

Each file: the context, the decision, why, and what was rejected. Name new ones `YYYY-MM-DD-short-title.md` and add them below, newest first.

| Date | Decision |
| --- | --- |
| 2026-10-03 | [Sub agents can open in a visible split](2026-10-03-spawn-into-a-split.md) |
| 2026-10-03 | [A reopened sub agent comes back in a hidden window](2026-10-03-resume-reopens-hidden.md) |
| 2026-10-03 | [An agent can spawn a sub agent for another agent](2026-10-03-spawn-for-another-agent.md) |
| 2026-10-03 | [A sub agent spawned for another agent isn't connected to the caller](2026-10-03-not-connected-to-the-caller.md) |
| 2026-10-03 | [Its depth counts from the agent that spawned it](2026-10-03-depth-counts-from-the-caller.md) |
| 2026-10-03 | [Its first message comes from its owner](2026-10-03-first-message-from-the-owner.md) |
| 2026-10-03 | [`tmux-ask --any` is unchanged by it](2026-10-03-any-unchanged.md) |
| 2026-10-03 | [The spawn depth limit stays at 2](2026-10-03-depth-limit-stays-2.md) |

---
name: wrap-up
description: Before the user clears the session, report what is worth saving and what is unfinished; after the clear, resume from the handoff. Use when the user says they will clear, reset or end the session, or says 收工 / 要清 session 了; or, after a clear, says "cleared, resume please", "cleared resume" or 清完了，继续.
---

Change nothing until the user picks.

- **Number the choices:** separate completed work worth recording, unfinished work that could continue, and live state that needs attention (background jobs, agents, worktrees, uncommitted or unpushed changes). Ask the user to choose what to save, continue or drop by number. Unselected old work stays pending, never resumes automatically.
- **Lessons not yet recorded:** user corrections, gotchas found, workflows explained only in chat, decisions and their reasons. Check repo docs, AGENTS.md, skills and memory first; drop what is already there or readable from the code. Also drop anything you got right on your own or caught yourself this session; keep only what would likely go wrong again without a note.
- **For each, propose a home and the wording:** an AGENTS.md rule, a repo doc, a skill, or memory (personal preference or setup), with one line of why.
- **List what you would skip,** with the reason, so the user can overrule.
- **After the choice:** save approved lessons to their agreed homes. Write information needed across a clear to the project-root `HANDOFF.md`: goal, roles and member names, relevant branches and worktree paths, live state, and the user's explicit choices, then a fixed "Resume steps" section: the commands the next session runs first (project-specific; none if nothing applies). Work not explicitly chosen to continue is listed only as pending selection.
- **Local handoff only:** before creating or updating `HANDOFF.md`, verify it is untracked and add `/HANDOFF.md` to the repository's local Git exclude file (`git rev-parse --git-path info/exclude`), not shared ignore rules. Never commit it. If already tracked, report the conflict before writing. Read any existing file first and preserve other chains' and the user's content.
- **Clear entries when resolved:** remove an entry only when completed, explicitly dropped, or transferred to a persistent record the user approved. Delete the file when every entry is resolved; reading it alone is not grounds for deletion. Leave unresolved entries for the next session.
- **Resume:** after a clear, read `HANDOFF.md`, run its Resume steps, then report the next actions to the user. Do not re-brief other agents or restore roles unless the user asks.

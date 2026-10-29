---
name: afk
description: Away mode until the user's next message, keep working and answering other agents, default and log decisions, brief the user on return. Use when the user says "afk", "brb" or that they are stepping away.
---

# AFK

The user has stepped away. **Away** lasts until their next message. Messages from agents (`[request from ... via tmux-ask]`, `[reply from ... via tmux-ask]`) and tool or task notifications keep the session away; only the user's own message ends it.

## While away

- Keep the work moving: answer agents, relay tasks, run checks and take the next step exactly as you would with the user watching.
- End each turn on the work itself (a sent message, a finished step). Save every question and status update for the user for the return brief.
- Decide what would otherwise wait for the user: pick the sensible default, act on it and log it. Hold a choice for the user only when it is hard to reverse or outward-facing (deleting, pushing, publishing, spending money); park that branch and carry on with other work.
- Keep the **away log** in a file (your scratchpad, or a temp directory) so it survives compaction. Append as you go:
  - **Done**: each finished piece of work.
  - **Decided for you**: each defaulted decision with its one-line reason.
  - **Waiting on you**: each parked question with your recommendation.

## On return

The user's next message ends away. Open your reply with the **return brief** built from the away log, its three sections in that order, a few lines each, then handle their message.

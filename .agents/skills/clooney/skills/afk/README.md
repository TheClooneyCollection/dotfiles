# afk

Away mode for when you step away from the keyboard. The agent keeps working until your next message, then opens with a brief of what happened.

**Why:** I used to step away and come back to an agent stalled on its first question. Now it keeps going, decides what it safely can, and briefs me on return.

**Use it:** say "afk", "brb" or that you are stepping away.

## What it does

- Keeps the work moving: answers other agents, runs checks, takes the next step.
- Picks sensible defaults for routine decisions and logs each one with its reason.
- Parks anything hard to reverse or outward-facing (deleting, pushing, publishing, spending) for you.
- Keeps an away log in a file, so it survives context compaction.
- When you return, briefs you from the away log in the [catch-up](../catch-up/SKILL.md) format, including defaulted decisions and their reasons.

## Needs

Written for agents that talk through [tmux-agents](https://github.com/TheClooneyCollection/tmux-agents). Without it, the away log and return brief still work.

Agent instructions: [SKILL.md](SKILL.md).

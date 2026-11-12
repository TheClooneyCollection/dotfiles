---
name: agent-docs
description: Write or edit documents agents read. Use when creating or changing a skill, or editing an AGENTS.md or CLAUDE.md.
---

Also read the file for the type: [skills.md](skills.md) for a skill, [agents-md.md](agents-md.md) for an AGENTS.md or CLAUDE.md.

- **Draft in chat first.** Show the whole change and wait for the user's go before writing files.
- **Only what the agent would not do anyway.** Test each line against a default agent and delete the whole line if it already does that. What earns a place: the user's corrections, gotchas found the hard way, conventions no file reveals, the reason behind a choice.
- **Point, don't copy.** Commands, config and layout the agent can read in the repo stay there; a copy goes stale.
- **One meaning, one place.** Update the existing line instead of adding a parallel one.
- **State the target behaviour.** A ban names the thing it bans; pair any hard guardrail with what to do instead.
- **Leading words.** A familiar word (tight, red, lesson) beats a sentence explaining it.

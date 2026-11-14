# agent-docs

Rules for writing documents that agents read: skills, `AGENTS.md` and `CLAUDE.md`. The aim is short files where every line changes what the agent does.

**Why:** Skill and AGENTS.md nowadays have a lot of what agents already knew. This trims those away to keep the lines that matter.

**Use it:** when creating or changing a skill, or editing an `AGENTS.md` or `CLAUDE.md`.

## What it does

- Drafts the change in chat first and waits for your go.
- Keeps only what a default agent would not do anyway: your corrections, hard-won gotchas, conventions no file reveals.
- Points to commands and config in the repo instead of copying them, so nothing goes stale.
- Gives each meaning one place, and pairs every ban with what to do instead.

## Files

- [SKILL.md](SKILL.md): the general rules.
- [skills.md](skills.md): extra rules for writing a skill.
- [agents-md.md](agents-md.md): extra rules for `AGENTS.md` and `CLAUDE.md`.

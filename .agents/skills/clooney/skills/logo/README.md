# logo

Designs a project logo with an image model and puts it at the top of the README.

**Why:** This aligns the icon, wordmark and dark-mode versions by building them all from the one image you picked.

**Use it:** ask for a logo, icon or wordmark.

## What it does

- Proposes directions and generates concepts; you pick one.
- Derives the icon, wordmark and monochrome versions by editing the image you picked, so the family stays consistent.
- Makes transparent light and dark versions and checks both on light and dark backgrounds.
- Adds a centred README header that switches between them, with the project name as a real heading.
- Commits only the logo files and the header.

## Needs

[Codex](https://github.com/openai/codex) for image generation. Other agents hand that part to a Codex agent.

Agent instructions: [SKILL.md](SKILL.md).

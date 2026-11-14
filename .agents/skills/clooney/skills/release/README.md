# release

Cuts a release by hand: works out the version from the commits, prepares and tags it, publishes the GitHub release, then runs the repo's own post-release steps.

**Why:** Releasing means a dozen small steps, and I would hate for me or an agent to ever forget one. Now the agent runs them in order: version, tag, GitHub release, follow-ups. This gives me the automation while keeping a framework and conventions for agents to follow, so releases stay intentional.

**Use it:** say "release", "cut a release" or "ship vX.Y.Z".

## What it does

1. **Preflight:** on `main`, clean, up to date with the remote, CI green.
2. **Version:** derives it from the commits since the last tag and shows you why; you confirm.
3. **Prepare:** bumps the version files, runs the checks, makes one release commit.
4. **Tag and push:** pushes the commit and tag together.
5. **Publish:** creates the GitHub release with notes from the changelog and a compare link.
6. **After release:** runs the repo's listed follow-up steps and reports each result.

## Setup

The repo's `AGENTS.md` (or `CLAUDE.md`) describes its release in `## Versioning` and `## Release` sections. If they are missing, the skill asks for the details once and writes them.

## Needs

The [GitHub CLI](https://cli.github.com) (`gh`), signed in.

Agent instructions: [SKILL.md](SKILL.md).

# new-project-setup

Sets up a new repository with a ready skeleton: Git, agent instructions, a docs layout and versioning rules. It adds no language, framework or build tooling; those come from the project later.

**Why:** Setting up Git, docs and versioning by hand for every new repo left each one slightly different. Now they all start the same.

**Use it:** ask to start, create, scaffold or initialise a new project or repo.

## What it does

1. Asks everything in one message, with defaults: name, description, versioning (`calver`, `semver` or `beta`), changelog notes, license, `.gitignore` style, docs language, GitHub remote.
2. Checks the target directory and asks before replacing anything.
3. Writes the skeleton from the templates and fills in the placeholders.
4. Makes the first commit and, if you asked for one, creates the GitHub repo after confirming its name and visibility.

## What you get

`AGENTS.md`, `CLAUDE.md`, `README.md`, `.gitignore`, a `docs/` tree (technical, development, product, research, decisions) and optionally a `LICENSE` and a changelog builder that turns one note per commit into `CHANGELOG.md`.

Swift and Xcode projects get extra setup from [references/swift.md](references/swift.md).

## Files

- [SKILL.md](SKILL.md): the agent's steps.
- [templates/](templates/): the files copied into the new repo.
- [references/](references/): extra steps for specific project types.

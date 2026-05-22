# AGENTS.md

Notes for AI agents working in this dotfiles repo.

- The Git repo root is `~/`. Dotfile directories like `.emacs.d/` are tracked subdirectories, not separate repos.
- Run shell and Git commands from the current working directory with relative paths. Do not use `git -C` or absolute paths in commands.
- This repo is mostly allowlisted through `.gitignore`. If a new root file should be tracked, update `.gitignore` explicitly.
- Follow the existing commit style: `feat(scope): ...`, `docs(scope): ...`, `chore(scope): ...`.
- Keep docs concise and practical. Add local workflow notes where future agents are likely to make the same mistake.

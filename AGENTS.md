# AGENTS.md

Notes for AI agents working in this dotfiles repo.

- The Git repo root is `~/`. Dotfile directories like `.emacs.d/` are tracked subdirectories, not separate repos.
- Run shell and Git commands from the current working directory with relative paths. Do not use `git -C` or absolute paths in commands.
- This repo is mostly allowlisted through `.gitignore`. If a new root file should be tracked, update `.gitignore` explicitly.
- Follow the existing commit style: `feat(scope): ...`, `docs(scope): ...`, `chore(scope): ...`.
- Releases are time-versioned, not semver. Use `vYYYY.MM.X`, where `YYYY` is the year, `MM` is the zero-padded month, and `X` is that month's release counter starting at `0`.
- Keep the month zero-padded consistently. Existing tags show an older inconsistency (`v2026.5.1` vs `v2026.05.0`); prefer `vYYYY.MM.X`.
- Do not imply semver meaning in release numbers. They are chronological snapshot labels for this dotfiles repo.
- Keep docs concise and practical. Add local workflow notes where future agents are likely to make the same mistake.

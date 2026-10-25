# AGENTS.md

Notes for AI agents working in this dotfiles repo.

- The Git repo root is `~/`. Dotfile directories like `.emacs.d/` are tracked subdirectories, not separate repos.
- Run shell and Git commands from the current working directory with relative paths. Do not use `git -C` or absolute paths in commands.
- This repo is mostly allowlisted through `.gitignore`. If a new root file should be tracked, update `.gitignore` explicitly.
- Follow the existing commit style: `feat(scope): ...`, `docs(scope): ...`, `chore(scope): ...`.
- Keep `main` linear: no merge commits. Land a branch with `git merge --ff-only`; if it does not fast-forward, rebase the branch onto `main` first. Never pass `--no-ff` or merge `main` into a branch.
- Releases are time-versioned, not semver. Use `vYYYY.MM.X`, where `YYYY` is the year, `MM` is the zero-padded month, and `X` is that month's release counter starting at `0`.
- Keep the month zero-padded consistently. Existing tags show an older inconsistency (`v2026.5.1` vs `v2026.05.0`); prefer `vYYYY.MM.X`.
- Do not imply semver meaning in release numbers. They are chronological snapshot labels for this dotfiles repo.
- Keep docs concise and practical. Add local workflow notes where future agents are likely to make the same mistake.

## tmux-agents install

- tmux-agents is developed in `~/Source/Projects/tmux-agents`. `~/.local/share/tmux-agents` is the installed copy: a clean clone of https://github.com/TheClooneyCollection/tmux-agents checked out at the latest release tag (detached HEAD). It is not tracked by dotfiles; never edit or commit in it.
- After each tmux-agents release, the agent that released it updates the installed copy (these `git -C` commands are the user's explicit exception to the no-`git -C` rule):
  1. `git -C ~/.local/share/tmux-agents fetch --tags`
  2. `git -C ~/.local/share/tmux-agents checkout vX.Y.Z`
  3. `cd ~/.local/share/tmux-agents && ./install.sh`. Checkout alone leaves the copied Codex rules (`~/.codex/rules`, `~/.codex-2nd/rules`) stale; `install.sh` refreshes them.
  4. `tmux-agents --chip-layout on`
- Roll back by checking out the previous tag the same way, then rerun `install.sh`.
- After each tmux-agents release, add a timeline entry for it on the blog (blog.clooney.io), using the tagged commit's time.

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

## tmux-agents sync

- `.local/share/tmux-agents` is a squashed subtree of https://github.com/TheClooneyCollection/tmux-agents.git (`main`). Changes may be made here or upstream; sync them both ways by default. When a task says not to release or sync, don't, and say in the reply what's left unsynced.
- Run subtree commands from the dotfiles repo root (`~`).
- Dotfiles → upstream: `git subtree push --prefix=.local/share/tmux-agents https://github.com/TheClooneyCollection/tmux-agents.git main`.
- Upstream → dotfiles: `GIT_LFS_SKIP_SMUDGE=1 git subtree pull --prefix=.local/share/tmux-agents https://github.com/TheClooneyCollection/tmux-agents.git main --squash`. Documentation images may stay as LFS pointers.
- `git subtree pull` needs a clean working tree. Keep the user's local commits and uncommitted files: never stash, reset or commit them for the sync; if the tree is dirty, pull in a temporary worktree and fast-forward `main`, then remove the worktree. After merging, check that the subtree (and `bin/`) matches upstream and that the user's local commits and files are still there.
- After each tmux-agents release, add a timeline entry for it on the blog (blog.clooney.io), using the tagged commit's time.

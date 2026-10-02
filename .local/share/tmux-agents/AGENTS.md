# AGENTS.md

Notes for AI agents working on tmux-agents.

## Testing

- **Never touch the user's tmux server.** Test on your own socket: `tmux -L <testname>`.
- Before pointing `TMUX=` at a test socket, check the server is up (`tmux -L <testname> has-session`) and the socket path is non-empty and not `*/default`. A failed test server plus an empty `TMUX` falls back to the user's server.
- Clean up with `tmux -L <testname> kill-server` only. Never run a bare `tmux kill-server`.
- Fake agents: point `TMUX_SPAWN_BIN` at a directory with stub `claude`/`codex` scripts.
- Target bash 3.2 (macOS): see [environment](docs/design/environment.md#macos-bash-32) and [pitfalls](docs/design/pitfalls-and-testing.md).

## Layout

`bin/` commands, `tmux/tmux-agents.conf` bindings and hooks, `skills/` agent skills, `integrations/` per-tool glue, `install.sh`. Keep README (users), DESIGN.md and docs/design/ (why and pitfalls) and the two skills in sync when behaviour changes.

## Commits and releases

- Commit style: `feat: ...`, `fix: ...`, `docs: ...`, `chore: ...`.
- Releases are semver tags `vX.Y.Z` with a GitHub release; add the notes to CHANGELOG.md first.
- The maintainer's dotfiles vendor this repo as a subtree at `.local/share/tmux-agents`. It may be changed in either place, but every change must be synced both ways (`git subtree push` / `git subtree pull --squash`, run from the dotfiles root; see the dotfiles' AGENTS.md).

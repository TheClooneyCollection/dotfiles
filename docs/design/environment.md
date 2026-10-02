# Environment

Part of the [design notes](../../DESIGN.md).

## macOS bash 3.2

`#!/usr/bin/env bash` resolves to `/bin/bash` 3.2 on macOS. Avoid:

- associative arrays, `mapfile`, `${var,,}`
- fractional `read -t` (integer timeouts only)

`name_form` reads keys with `read -rsn1` and parses escape sequences with `read -rsn2 -t 1`. More bash traps are in [pitfalls](pitfalls-and-testing.md#pitfalls-found-while-building).

## Codex sandbox

Codex's seatbelt sandbox denies the tmux socket (`error connecting to /private/tmp/tmux-501/... (Operation not permitted)`). This was confirmed with `codex sandbox`; `--allow-unix-socket` fixes it.

The shipped fix is `integrations/codex/tmux-agents.rules`, which `install.sh` copies into each Codex home's `rules/`. It allows the commands agents use with `prefix_rule(..., decision="allow")`. `codex execpolicy check` confirms the decision, including absolute paths via `--resolve-host-executables`.

In practice the allowed commands run without a prompt. The skill keeps a fallback (ask for escalated permissions) and asks agents to run `tmux-*` commands on their own: prefix rules only match a command's start, so a chained command such as `echo ...; tmux-peers` runs sandboxed, and tmux reports the blocked socket as "no tmux server running". `require_tmux` now says what happened when `$TMUX` is set.

Rules files must be copies, not symlinks: Codex silently ignores symlinked `.rules` files ([openai/codex#32658](https://github.com/openai/codex/issues/32658), open), because `collect_policy_files()` keeps only `is_file()` entries. A symlinked rules file in a second Codex account was skipped, so that account prompted for `tmux-peers`; its log showed the `CommandExecutionRequestApproval`.

Prefix allow rules may still prompt for sandbox escapes ([openai/codex#15298](https://github.com/openai/codex/issues/15298), reported on Windows). If Codex still asks, approving with "don't ask again" writes a rule to that account's `default.rules`, which works.

## Codex runs commands in a shared daemon

Codex runs shell commands in a shared app-server daemon, one per `CODEX_HOME`, which keeps the environment of the pane it was started from. The main Codex daemon has no `TMUX_PANE` at all. So `$TMUX_PANE` inside a Codex command can be another agent's pane:

- A Codex sub agent ran `tmux-ask` with its parent's `TMUX_PANE`, so it acted as its parent and got "not connected". `ps eww` showed the TUI with `%40` and the daemon with `%36`.
- A top-level Codex started without pins ran `tmux-peers`, saw its parent's identity, asked the user to confirm that name, got a "yes", and messaged another project's agent as someone else.
- `TMUX_AGENTS_DEPTH` had the same problem, which silently broke the depth limit for Codex.

The fixes:

- **`--from` identity in every message** (see [protocol](state-and-protocol.md#design-decisions)).
- **`shell_environment_policy.set` pins** (`TMUX_PANE`, `TMUX`, `TMUX_AGENTS_PINNED=1`) for every Codex started in tmux. `tmux-spawn --run` adds them for sub agents (plus `TMUX_AGENTS_DEPTH`), and the `codex` wrappers in `integrations/` add them (via `__codex_tmux_pins`) for Codex the user starts.
- **No guessing.** The skill no longer lets an unpinned Codex pick a name from `tmux-peers` or have the user confirm one, and `tmux-peers` prints a warning when neither `--from`, `TMUX_AGENTS_PINNED` nor `CLAUDECODE` is set.

Verified live: a Codex on a second account, restarted through the wrapper, saw `TMUX_AGENTS_PINNED=1` and `you: codex-~-1 (%48)` while sharing the daemon started from `%36`.

## Permissions

- **Allowed for agents** (`integrations/claude/settings.json`, `integrations/codex/tmux-agents.rules`): `tmux-ask`, `tmux-peers`, `tmux-peek`, `tmux-spawn`, `tmux-agent-report`, and the `--from` forms of `tmux-connect` and `tmux-dismiss`. `tmux-connect --from` is the [agent mode](state-and-protocol.md#agent-mode) used when the user asks an agent to connect; `tmux-dismiss --from` checks the agent spawned what it closes.
- **Left to the user:** interactive `tmux-connect`, `tmux-disconnect`, plain `tmux-dismiss` and `--done`.

## Layout

| Piece | In this repo | Installed to |
| --- | --- | --- |
| Commands | `bin/` | `~/.local/bin` (`BIN_DIR`), linked by `install.sh` |
| Key bindings, hooks, chip settings | `tmux/tmux-agents.conf` | `source-file` it from `~/.tmux.conf` after setting `%hidden TMUX_AGENTS_BIN` |
| Skills | `skills/claude/`, `skills/codex/`, `skills/tmux-agents-setup/` | linked into `~/.claude/skills/` and each Codex home's `skills/` |
| Codex rules | `integrations/codex/tmux-agents.rules` | copied into each Codex home's `rules/` (Codex skips symlinked rules) |
| Codex wrappers | `integrations/fish/`, `integrations/sh/` | your shell config |
| Claude permissions | `integrations/claude/settings.json` | merged into `~/.claude/settings.json` by hand |

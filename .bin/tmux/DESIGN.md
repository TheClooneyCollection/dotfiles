# tmux agents: design notes

How the `tmux-*` scripts work, why they work that way, and the traps found while building them. For usage, see [README.md](README.md).

## Goals

- Agents (Claude, Codex, anything) in ordinary tmux panes can message each other.
- The user watches every pane and makes every permission decision in the agent's own UI.
- Any number of panes, connected ad hoc. There is no fixed layout or session launcher.
- No daemon and no state files.

## Architecture

### State lives on panes

Everything is stored as tmux user options on the panes themselves (`set-option -p`):

| Option | Meaning |
| --- | --- |
| `@agent` | The pane's name, unique across the tmux server. |
| `@peers` | Space-separated pane ids (`%12`) this pane links to. |
| `@peer_names` | Cached `name, name` string for the border label. |

Windows that hold named panes also get `@agents_border=1`, plus window-level `pane-border-status top` and `pane-border-format`. The marker lets `refresh_labels` undo only the border settings it set itself.

Why pane options:
- **Stable ids.** Pane ids survive moving panes between windows and sessions.
- **Automatic cleanup.** Closing a pane deletes its options. Other panes' `@peers` still list the dead id until `get_peers` prunes it on the next read.
- **Nothing to sync.** There are no files to go stale, and `tmux show -p @peers` is the whole debugging story.

### Links

- Links are one-to-one and symmetric. `tmux-connect` writes both sides.
- They are not transitive: A↔B plus B↔C does not link A↔C, so the user always knows who can reach whom.
- `tmux-ask` and `tmux-peek` refuse unlinked targets (`resolve_peer`).

### Scripts

| File | Role |
| --- | --- |
| `lib.sh` | Shared helpers, sourced by the others. Holds pane lookup, naming, peers, labels. |
| `tmux-connect` | Picker, naming form, linking, popup mode. |
| `tmux-disconnect` | Removes links. |
| `tmux-peers` | Lists connections. `--refresh` rebuilds labels (used by hooks). |
| `tmux-ask` | Sends a message. |
| `tmux-peek` | Reads a peer's screen (`capture-pane -J`). |

`lib.sh` is not executable, so it never shows up as a command even though the directory is on `PATH`.

## Message protocol

`tmux-ask` pastes text into the target pane and presses Enter, exactly as if the user had typed it. The agent receives it as an ordinary prompt.

```
[request from claude via tmux-ask]
<message>

(When done, send your answer back with: tmux-ask --reply claude <<'MSG'
<your reply>
MSG)
```

```
[reply from codex via tmux-ask]
<message>

(This is a reply. Do not answer it unless you have a new request.)
```

Design decisions:
- **Push, not call-and-wait.** The sender ends its turn right after sending. The answer arrives later as a new prompt in its own pane. An earlier design blocked on `tmux wait-for` plus a Stop/notify hook and scraped the reply with `capture-pane`. It was dropped because a peer waiting on a permission prompt would stall the caller, and scraped TUI output is noisy.
- **Loop prevention by convention.** Replies say not to answer. The `tmux-agents` skill repeats the rule. There is no hop counter.
- **Every request carries its own reply instructions.** An agent that never loaded the skill can still answer.
- **Delivery.** The script loads the message into a tmux buffer and uses `paste-buffer -p` (bracketed paste), so multi-line text stays one message. It then waits `TMUX_ASK_ENTER_DELAY` (default 0.5s) before sending Enter, because TUIs can treat an Enter that arrives in the same burst as the paste as a newline.
- **Trust.** Peer messages look like user input. The skill tells agents that the user's instructions win and to confirm anything destructive with the user.

## Naming

- `suggest_name` builds `<command>-<dir>-<N>`:
  - `dir` is the cwd basename, or `~` for `$HOME`.
  - Shells (`fish`, `zsh`, `bash`, ...) are left out of the prefix, because a pane about to start an agent still reports its shell.
  - `N` is one past the highest number in use with that prefix. Gaps are not reused.
  - Extra arguments count as taken, so two suggestions made in the same run don't collide.
- `sanitize_name` maps anything outside `A-Za-z0-9._~-` to `-`.
- `set_name` refuses names held by another pane.
- `tmux-connect` names every unnamed pane in one form (`name_form`): ↑/↓/Tab switch fields, typing appends, Backspace deletes, Ctrl-U clears, and one Enter accepts all. Without a TTY it reads one line per field, which the tests rely on.

## Picker and popup

- The picker lists panes in the current window by default (`--all` for every window).
- It dedupes by pane id, because grouped sessions list a shared window once per session.
- fzf's `focus` event runs `tmux-connect --highlight <id>`, which sets pane-level `window-style` (`TMUX_CONNECT_HIGHLIGHT`, default `bg=colour24`) on the focused pane and clears it on the other candidates. The `EXIT` trap clears it on pick, cancel, and error.
- The `prefix + A` binding is:
  ```
  bind A run-shell -b "tmux display-popup -c '#{client_name}' -E ... '$HOME/.bin/tmux/tmux-connect --popup --from #{pane_id}'"
  ```
- `--popup` makes the popup close by itself on success (the result goes to `display-message`) and pause for Enter only on errors.

## Environment constraints

### macOS bash 3.2

`#!/usr/bin/env bash` resolves to `/bin/bash` 3.2 here. Avoid:
- associative arrays, `mapfile`, `${var,,}`
- fractional `read -t` (integer timeouts only)

`name_form` reads keys with `read -rsn1` and parses escape sequences with `read -rsn2 -t 1`.

### Codex sandbox

Codex's seatbelt sandbox denies the tmux socket (`error connecting to /private/tmp/tmux-501/... (Operation not permitted)`). This was confirmed with `codex sandbox`; `--allow-unix-socket` fixes it.

The shipped fix is `~/.codex/rules/tmux-agents.rules`, which allows `tmux-ask`, `tmux-peers` and `tmux-peek` with `prefix_rule(..., decision="allow")`. `codex execpolicy check` confirms the decision, including absolute paths via `--resolve-host-executables`.

**Unverified:** whether an allow rule alone also runs the command outside the sandbox in a live session. The Codex skill keeps a fallback: request escalated permissions.

### Permissions

- Claude: `tmux-ask`, `tmux-peers` and `tmux-peek` (bare and `~/.bin/tmux/` forms) are allowlisted in `~/.claude/settings.json`.
- `tmux-connect` and `tmux-disconnect` are deliberately not allowlisted anywhere. Connecting panes is the user's call.

### Where things are installed

| Piece | Location |
| --- | --- |
| Scripts | `~/.bin/tmux/`, on `PATH` via `.config/fish/config.fish` |
| Binding and hooks | `~/.tmux.conf` (`pane-exited[42]` and `after-kill-pane[42]` run `tmux-peers --refresh`) |
| Skills | `~/.claude/skills/tmux-agents/`, `~/.codex/skills/tmux-agents/` |
| Codex rules | `~/.codex/rules/tmux-agents.rules` |

`~/.codex-2nd/` symlinks the Codex skill, rules and `AGENTS.md` with relative links.

## Pitfalls found while building

- **`display-popup` doesn't expand `#{...}` in its command.** A literal `#{pane_id}` reached `sh`, where `#` starts a comment, so the command silently lost its arguments. Wrap it in `run-shell`, which does expand formats. Use `-b` so the command queue isn't blocked while the popup waits for input.
- **`display-message -t %99 '#{pane_id}'` exits 0 with empty output for a closed pane.** `pane_alive` checks `list-panes -a` instead.
- **`set -o pipefail` plus `grep -q`.** `grep` exits early, the writer gets SIGPIPE, and the pipeline "fails". Capture output into a variable before grepping (`is_peer`, `pane_alive`).
- **Grouped sessions** duplicate panes in `list-panes -a`. Dedupe by id.
- **Font ligatures** can render `-~-` as an arrow (`claude-~-1` shows as `claude⤳1`). This is cosmetic only.

## Testing

Tests never touch the user's server:
- Run scripts against a separate server (`tmux -L <name> -f /dev/null`) by exporting `TMUX=<socket>,1,0` and `TMUX_PANE=%N`.
- To test key bindings and popups, run an inner server with `-f ~/.tmux.conf` attached inside a pane of an outer server. Drive it with `tmux -L outer send-keys` and read the screen with `capture-pane`.
- `cat` panes stand in for agents. The TTY echo makes them show pasted text twice, which is expected.
- Pace simulated keystrokes (about 0.1s apart). A single `send-keys` burst of Down plus Backspaces didn't register the Backspaces in the popup form, while paced keys did.

## Known limitations

- The naming form edits only at the end of a field (no ←/→ cursor).
- A message pasted while the user is typing in that pane gets mixed with the typing. Claude queues input while busy; Codex's behaviour is untested.
- There is no hop limit beyond the reply convention.
- `@peer_names` is a cache. Renaming a pane by hand (`set -p @agent`) needs `tmux-peers --refresh`.

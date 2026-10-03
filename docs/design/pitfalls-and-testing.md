# Pitfalls and testing

Part of the [design notes](../../DESIGN.md).

## Pitfalls found while building

### tmux

- **`display-popup` doesn't expand `#{...}` in its command.** A literal `#{pane_id}` reached `sh`, where `#` starts a comment, so the command silently lost its arguments. Wrap it in `run-shell`, which does expand formats. Use `-b` so the command queue isn't blocked while the popup waits for input.
- **`display-message -t %99 '#{pane_id}'` exits 0 with empty output for a closed pane.** `pane_alive` checks `list-panes -a` instead.
- **Grouped sessions** duplicate panes in `list-panes -a`. Dedupe by id.
- **`send-keys` goes to copy mode.** If the user is scrolling the receiver's pane, `paste-buffer` still reaches the program (it bypasses modes) but `send-keys Enter` is handled by copy mode, so the message sat in the input box unsent. Pasting a raw `\r` instead worked for `cat` but not for Claude Code, whose input didn't submit on it. So `user_busy` counts `#{pane_in_mode}` as busy: someone scrolling a pane is reading it, and the message is queued until they leave copy mode.
- **Nested `tmux attach` after `unset TMUX` goes to the default socket.** On a `-L` test server it attached to the user's real server. `--view` passes `-S` with the socket taken from `$TMUX`.
- **New windows run through the user's shell, whose startup file can reorder `PATH`.** A test put fake agents first on the server's `PATH`, but fish moved `~/.local/bin` ahead of them, so the real `claude` started with the test task. It was killed within about a second. `TMUX_SPAWN_BIN` is now the test hook: `--run` prepends it after fish has run.

### Shell

- **`set -o pipefail` plus `grep -q`.** `grep` exits early, the writer gets SIGPIPE, and the pipeline "fails". Capture output into a variable before grepping (`is_peer`, `pane_alive`).
- **`grep -v` that filters out every line exits 1.** Under `pipefail` and `set -e`, removing the only name from `@closed` silently killed `tmux-spawn` halfway through linking. Use `awk` for filters that can come out empty.
- **`read` with `IFS=<tab>` collapses empty fields**, because tab is IFS whitespace. An empty `@parent` shifted every later column. Formats emit `-` for empty values.
- **`basename ... | tr -c` also translates the trailing newline** into the replacement character. Sanitize `"$(basename ...)"` through `printf '%s'` instead.
- **`$(...)` turns off `set -e`** inside it, so helpers called that way must return failure explicitly (see `auto_name` in [naming](state-and-protocol.md#naming)).

### Codex

- **Chained commands run in the sandbox**, and **symlinked rules files are ignored**. See [Codex sandbox](environment.md#codex-sandbox).
- **`$TMUX_PANE` can be another pane's**, because commands run in a shared daemon. See [the shared daemon](environment.md#codex-runs-commands-in-a-shared-daemon).

### Display

- **Font ligatures** can render `-~-` as an arrow (`claude-~-1` shows as `claude⤳1`). This is cosmetic only.

## Testing

- `tests/needs-you.sh` runs the real scripts on an isolated server with `cat` panes as agents, simulating Claude's hooks and Codex's notify, and checks the "needs you" state machine: normal workflows that must not flag a sub agent (replying, waiting on its own sub agents, requests or `--waiting` work, notices, Codex's title thread) and real cases that must.
Tests never touch the user's server:

- Run scripts against a separate server (`tmux -L <name> -f /dev/null`) by exporting `TMUX=<socket>,1,0` and `TMUX_PANE=%N`.
- To test key bindings and popups, run an inner server with `-f ~/.tmux.conf` attached inside a pane of an outer server. Drive it with `tmux -L outer send-keys` and read the screen with `capture-pane`.
- `cat` panes stand in for agents. The TTY echo makes them show pasted text twice, which is expected.
- For `tmux-spawn`, always set `TMUX_SPAWN_BIN` to a directory of fake `claude`/`codex` scripts that print their arguments and `exec cat`. Check the new pane shows the fake's marker before doing anything else, and kill the server if it doesn't.
- Pace simulated keystrokes (about 0.1s apart). A single `send-keys` burst of Down plus Backspaces didn't register the Backspaces in the popup form, while paced keys did.

## Known limitations

- The naming form edits only at the end of a field (no ←/→ cursor).
- A message pasted while the user is typing in that pane gets mixed with the typing. Claude queues input while busy; Codex's behaviour is untested.
- There is no hop limit beyond the reply convention.
- Using `tmux-spawn` instead of built-in sub agents is an instruction, not enforcement.
- A Codex started without the wrappers (e.g. `command codex`, another shell, or the desktop app) still can't know its own name until it receives a message. The skill tells it to ask the user for its pane's name.
- Viewing a hidden agent attaches a second client to its session, which resizes that session's windows to the popup.
- `@peer_names` is a cache. Renaming a pane by hand (`set -p @agent`) needs `tmux-peers --refresh`.

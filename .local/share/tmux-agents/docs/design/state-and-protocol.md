# State and protocol

Part of the [design notes](../../DESIGN.md).

## State lives on panes

Everything is stored as tmux user options on the panes themselves (`set-option -p`):

| Option | Meaning |
| --- | --- |
| `@agent` | The pane's name, unique across the tmux server. |
| `@peers` | Space-separated pane ids (`%12`) this pane links to. |
| `@peer_names` | Cached `name, name` string for the border label. |
| `@parent` | On spawned sub agents: the pane id that spawned them. |
| `@closed` | Names of peers the user closed (set by `note_closed` before `kill-pane`). |
| `@state` | On sub agents: `done`, `working` or `needs_you`. See [done state](sub-agents.md#done-state-and-cleanup) and [chip data](sub-agents.md#data-not-screen-scraping). |
| `@awaiting` | Names this pane sent requests to and hasn't had a reply from yet. |
| `@activity`, `@waiting_on`, `@perm_since` | Sub agent reports for the [status chip](sub-agents.md#status-chip). |
| `@attention_since`, `@codex_thread` | When a sub agent started needing the user; the Codex thread id of a sub agent, for `notify`. |

Windows that hold named panes also get `@agents_border=1`, plus window-level `pane-border-status top` and `pane-border-format`. The marker lets `refresh_labels` undo only the border settings it set itself.

Why pane options:

- **Stable ids.** Pane ids survive moving panes between windows and sessions.
- **Automatic cleanup.** Closing a pane deletes its options. Other panes' `@peers` still list the dead id until `get_peers` prunes it on the next read.
- **Nothing to sync.** There are no files to go stale, and `tmux show -p @peers` is the whole debugging story.

## Links

- Links are one-to-one and symmetric. `tmux-connect` writes both sides.
- They are not transitive: A↔B plus B↔C does not link A↔C, so the user always knows who can reach whom.
- `tmux-ask` and `tmux-peek` refuse unlinked targets (`resolve_peer`). `tmux-ask --any` skips the check and resolves any named pane; the request's reply instructions carry `--any` so the receiver can answer. The receiver must have a name.

## Naming

- `suggest_name` builds `<command>-<dir>-<N>`:
  - `dir` is the cwd basename, or `~` for `$HOME`.
  - Shells (`fish`, `zsh`, `bash`, ...) are left out of the prefix, because a pane about to start an agent still reports its shell.
  - `N` is one past the highest number in use with that prefix. Gaps are not reused.
  - Extra arguments count as taken, so two suggestions made in the same run don't collide.
- `sanitize_name` maps anything outside `A-Za-z0-9._~-` to `-`.
- `set_name` refuses names held by another pane.
- **Checked step by step.** `auto_name` runs inside `$(...)`, where `set -e` doesn't apply, so it returns failure explicitly when `set_name` fails, and every caller dies on it. Checking a name and writing it isn't atomic, so after writing it confirms no other pane holds the same name; otherwise it clears its own and retries with the next number after a short random pause.
- **Unnamed panes name themselves.** A freshly opened agent has no `@agent`. When its `$TMUX_PANE` can be trusted (Claude, or Codex with `TMUX_AGENTS_PINNED`), `tmux-ask`, `tmux-peers`, `tmux-spawn`, and any command given an unknown `--from` give that pane a generated name (`auto_name`) and print it, so the agent can carry on with it. This came up when an unnamed Claude copied `--from claude` from the skill's example and `tmux-spawn` failed on `no agent named 'claude'`; the examples now use a placeholder. Unpinned Codex still gets an error, since its `$TMUX_PANE` may be another agent's pane (see [environment](environment.md#codex-runs-commands-in-a-shared-daemon)).

## Connecting

### Picker and popup (the user)

- The picker lists panes in the current window by default (`--all` for every window).
- It dedupes by pane id, because grouped sessions list a shared window once per session.
- fzf's `focus` event runs `tmux-connect --highlight <id>`, which sets pane-level `window-style` (`TMUX_CONNECT_HIGHLIGHT`, default `bg=colour24`) on the focused pane and clears it on the other candidates. The `EXIT` trap clears it on pick, cancel and error.
- `tmux-connect` names every unnamed pane in one form (`name_form`): ↑/↓/Tab switch fields, typing appends, Backspace deletes, Ctrl-U clears, and one Enter accepts all. Without a TTY it reads one line per field, which the tests rely on.
- The `prefix + A` binding is:
  ```
  bind A run-shell -b "tmux display-popup -c '#{client_name}' -E ... '$HOME/.bin/tmux/tmux-connect --popup --from #{pane_id}'"
  ```
  `display-popup` doesn't expand formats, hence the `run-shell` wrapper (see [pitfalls](pitfalls-and-testing.md#pitfalls-found-while-building)).
- `--popup` makes the popup close by itself on success (the result goes to `display-message`) and pause for Enter only on errors.

### Agent mode

`tmux-connect --from ME <target>` without `--popup` is agent mode, used when the user asks an agent to connect: no picker and no naming form. Permissions allow only this `--from` form.

- A target of `codex` or `claude` means the agent type. It resolves to the single other pane in the caller's window whose `pane_current_command` equals it, or whose name is it or starts with `codex-`/`claude-`.
- Any other target is an exact name (this window first, then anywhere) or a pane id.
- Several matches or none is an error listing the window's panes, so the agent asks the user.
- Unnamed panes are named with `auto_name`.

An earlier version matched names globally first and command substrings for any target, so `codex` could pick a pane of that name in another window and `code` matched `codex-notes`. Codex's review of the change caught both.

## Message protocol

`tmux-ask` pastes text into the target pane and presses Enter, exactly as if the user had typed it. The agent receives it as an ordinary prompt.

```
[request from claude to codex via tmux-ask]
<message>

(You are codex. When done, send your answer back with: tmux-ask --from codex --reply claude <<'MSG'
<your reply>
MSG)
[end of request from claude to codex]
```

```
[reply from codex to claude via tmux-ask]
<message>

(This is a reply. Do not answer it unless you have a new request.)
[end of reply from codex to claude]
```

### Design decisions

- **Push, not call-and-wait.** The sender ends its turn right after sending, and the answer arrives later as a new prompt in its own pane. An earlier design blocked on `tmux wait-for` plus a Stop/notify hook and scraped the reply with `capture-pane`. It was dropped because a peer waiting on a permission prompt would stall the caller, and scraped TUI output is noisy.
- **Loop prevention by convention.** Replies say not to answer, and the `tmux-agents` skill repeats the rule. There is no hop counter.
- **Explicit identity.** Every request names its receiver and puts `--from <receiver>` in the reply command. `self_pane` takes `--from` (a name or pane id) before `$TMUX_PANE`, because `$TMUX_PANE` can be wrong in Codex.
- **Every request carries its own reply instructions**, so an agent that never loaded the skill can still answer.
- **End markers.** Bodies end with `[end of request|reply from X to Y]`. If a user's draft gets submitted along with a message, the skill tells the agent that text outside the markers is the user's, with the user's authority.
- **Trust.** Peer messages look like user input. The skill tells agents that the user's instructions win and to confirm anything destructive with the user.

### Delivery

`tmux-ask` loads the message into a tmux buffer and uses `paste-buffer -p` (bracketed paste), so multi-line text stays one message. It waits `TMUX_ASK_ENTER_DELAY` (default 0.5s), because TUIs can treat an Enter that arrives in the same burst as the paste as a newline, then submits with `send-keys Enter`.

### Not typing over the user

`user_busy` is true when the receiver's pane is in copy mode (where `send-keys Enter` would go to copy mode instead of the program), or a client is showing it and had a keypress in the last `TMUX_ASK_IDLE_SECS` (8s). Then:

1. `tmux-ask` writes the body to `/tmp/tmux-agents-<uid>/queue/<socket>/<epoch>-<pid>-<pane>.msg`. It is one fixed place per tmux server, so hooks running in the server's environment find it, and per server because pane ids repeat across servers (a test server's `%1` is not the user's `%1`).
2. It starts `tmux-ask --deliver` with `run-shell -b`, so the deliverer lives in the tmux server rather than the sender, and prints `queued`. The skill tells agents that `queued` means sent, so they don't resend.
3. The deliverer polls every 2s, waits for older queued files for the same pane (names sort by time), and delivers once the user is idle. A pane in copy mode with no keypress from a client showing it for `TMUX_ASK_COPY_IDLE_SECS` (default 300, 0 = never) was probably left there by accident: the deliverer cancels copy mode (`send-keys -X cancel`), tells the clients, and delivers. Settings reach the deliverer explicitly on its command line, because `run-shell` runs with the server's environment, not the sender's.
4. It gives up after `TMUX_ASK_QUEUE_SECS` (30 min) or when the pane is gone. Giving up renames the file to `.undelivered`, so it no longer holds up later messages, and shows every client where it is for 10s.

Leaving copy mode doesn't wait for the poll: a `pane-mode-changed[42]` hook runs `tmux-ask --kick <pane>`, which sends that pane's queued messages at once, in order, skipping the typing window. tmux counts mouse scrolling as client activity, so waiting it out cost 8 to 10s after every scroll. The hook and the deliverer can race for the same file, so each claims it by renaming it to `.sending` first; the loser finds it gone and exits.

Detecting drafts in the input line from the screen was prototyped and dropped: it depended on each TUI's look (Codex draws its placeholder dim), and the end markers make it unnecessary.

## Long messages

- **Convention.** The skill asks for a 3 to 5 line summary plus a file path whenever an answer runs past about 20 lines. Claude writes to its session scratchpad; other agents write to `$TMPDIR/tmux-agents/<name>/`.
- **Safety net.** Messages over `TMUX_ASK_MAX_LINES` (default 60) are written to `$TMPDIR/tmux-agents/<sender>/<time>-to-<receiver>.md`. Only the first 15 lines and the path are pasted, which keeps huge pastes out of TUIs.

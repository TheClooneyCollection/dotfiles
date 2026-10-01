# tmux agents: design notes

How the `tmux-*` scripts work, why they work that way, and the traps found while building them. For usage, see [README.md](README.md).

## Goals

- Agents (Claude, Codex, anything) in ordinary tmux panes can message each other.
- The user watches every pane and makes every permission decision in the agent's own UI.
- Any number of panes, connected ad hoc. There is no fixed layout or session launcher.
- No daemon and no state files.
- Sub agents are real agents in their own panes, hidden by default but one keystroke away, so their full history stays readable.

## Architecture

### State lives on panes

Everything is stored as tmux user options on the panes themselves (`set-option -p`):

| Option | Meaning |
| --- | --- |
| `@agent` | The pane's name, unique across the tmux server. |
| `@peers` | Space-separated pane ids (`%12`) this pane links to. |
| `@peer_names` | Cached `name, name` string for the border label. |
| `@parent` | On spawned sub agents: the pane id that spawned them. |
| `@closed` | Names of peers the user closed (set by `note_closed` before `kill-pane`). |
| `@state` | On sub agents: `done` after replying to the parent, `working` after receiving a request or reporting, `needs_you` after a turn that ended without either and without waiting on anyone. |
| `@awaiting` | Names a pane sent requests to and hasn't had a reply from yet. |
| `@attention_since`, `@codex_thread` | When a sub agent started needing the user; the Codex thread id of a sub agent, for `notify`. |

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
| `tmux-spawn` | Starts a connected sub agent in a hidden window. `--run` is its in-window half. |
| `tmux-agents` | fzf switcher (`prefix + a`). `--list`, `--view` and `--alert` are its helper modes. |
| `tmux-dismiss` | Kills an agent's pane. |

`lib.sh` is not executable, so it never shows up as a command even though the directory is on `PATH`.

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

Design decisions:
- **Push, not call-and-wait.** The sender ends its turn right after sending. The answer arrives later as a new prompt in its own pane. An earlier design blocked on `tmux wait-for` plus a Stop/notify hook and scraped the reply with `capture-pane`. It was dropped because a peer waiting on a permission prompt would stall the caller, and scraped TUI output is noisy.
- **Loop prevention by convention.** Replies say not to answer. The `tmux-agents` skill repeats the rule. There is no hop counter.
- **Agents connect on request.** `tmux-connect --from ME <target>` without `--popup` is agent mode: no picker and no naming form. A target of `codex` or `claude` resolves to the single other pane in the caller's window whose `pane_current_command` contains it or whose name starts with it; several or none is an error listing the window's panes, so the agent asks the user. Unnamed panes are named with `auto_name`. Permissions allow only this `--from` form.
- **Unnamed panes name themselves.** A freshly opened agent has no `@agent`. When its `$TMUX_PANE` can be trusted (Claude, or Codex with `TMUX_AGENTS_PINNED`), `tmux-ask`, `tmux-peers`, `tmux-spawn`, and any command given an unknown `--from`, give that pane a generated name (`auto_name`, `<command>-<dir>-<N>`) and print it, so the agent can carry on and use it. This came up when an unnamed Claude copied `--from claude` from the skill's example and `tmux-spawn` failed on `no agent named 'claude'`; the examples now use a placeholder. Unpinned Codex still gets an error, since its `$TMUX_PANE` may be another agent's pane.
- **Unconnected panes.** `tmux-ask --any` skips the connection check and resolves any named pane; the request's reply instructions carry `--any` so the receiver can answer. The receiver must have a name.
- **Explicit identity.** Every request names its receiver and puts `--from <receiver>` in the reply command. `self_pane` takes `--from` (a name or pane id) before `$TMUX_PANE`, because `$TMUX_PANE` is wrong in Codex (see pitfalls).
- **Every request carries its own reply instructions.** An agent that never loaded the skill can still answer.
- **Delivery.** The script loads the message into a tmux buffer and uses `paste-buffer -p` (bracketed paste), so multi-line text stays one message. It then waits `TMUX_ASK_ENTER_DELAY` (default 0.5s) before sending Enter, because TUIs can treat an Enter that arrives in the same burst as the paste as a newline. It then submits with `send-keys Enter`, which is why a pane in copy mode counts as busy (see pitfalls).
- **Not typing over the user.** `user_busy` is true when the receiver's pane is in copy mode, or a client is showing it and had a keypress in the last `TMUX_ASK_IDLE_SECS` (8s). Then `tmux-ask` writes the body to `/tmp/tmux-agents-<uid>/queue/<epoch>-<pid>-<pane>.msg` (one fixed place, so hooks running in the tmux server's environment find it) and starts `tmux-ask --deliver` with `run-shell -b`, which lives in the tmux server rather than the sender. The deliverer polls every 2s, waits for older queued files for the same pane (names sort by time), delivers once the user is idle, and gives up after `TMUX_ASK_QUEUE_SECS` (30 min) or when the pane is gone. Giving up renames the file to `.undelivered`, so it no longer holds up later messages, and shows every client where it is for 10s. Leaving copy mode doesn't wait for the poll: a `pane-mode-changed[42]` hook runs `tmux-ask --kick <pane>`, which sends that pane's queued messages at once, in order, skipping the typing window (tmux counts mouse scrolling as client activity, so waiting it out cost 8 to 10s after every scroll). The hook and the deliverer can race for the same file, so each claims it by renaming it to `.sending` first; the loser finds it gone and exits. The sender already got `queued` back and has moved on; the skill tells agents that `queued` means sent, so they don't resend. Detecting drafts in the input line from the screen was prototyped and dropped: it depended on each TUI's look (Codex draws its placeholder dim) and the end markers make it unnecessary.
- **End markers.** Bodies end with `[end of request|reply from X to Y]`. If a user's draft gets submitted with a message, the skill tells the agent that text outside the markers is the user's, with the user's authority.
- **Trust.** Peer messages look like user input. The skill tells agents that the user's instructions win and to confirm anything destructive with the user.

## Sub agents

Agents are told (skill, Claude memory, `~/.codex/AGENTS.md`) to use `tmux-spawn` wherever they would use a built-in sub agent. Built-in subagents can't be switched off, so this is an instruction, not enforcement.

### Spawning

1. **Refuse if too deep.** `TMUX_AGENTS_DEPTH` (unset means 0) must be below `TMUX_AGENTS_MAX_DEPTH` (default 2). The child gets depth + 1 through `new-window -e`, so a top-level agent can spawn children, and they can spawn grandchildren, which can't spawn further.
2. **Pick the agent kind.** An explicit `claude|codex|codex-2nd` wins. Otherwise: `CLAUDECODE` set means claude; `CODEX_HOME=~/.codex-2nd` means codex-2nd; then the caller pane's `pane_current_command`.
3. **Name the caller** with `suggest_name` if it has no name, so the child can reply.
4. **Name the child.** `--name` is sanitized and made unique with `unique_name` (`-2`, `-3`...). Without it, `name_for <agent> <cwd>` gives `claude-<dir>-<N>`.
5. **Pick the session.** It is `agents-<project>`, from `agents_session_for`: the git root's basename, `home` for `$HOME`, else the directory's basename. It is created with `new-session -d` on first use. One window per sub agent.
6. **Hand over the task through a file.** The request body goes to a `mktemp` file. The window runs `tmux-spawn --run <agent> <file>`, which reads and deletes it and `exec`s the agent with the text as its first prompt (`claude "<prompt>"` and `codex "<prompt>"` both start interactive with an initial prompt). No shell ever quotes the task, and nothing has to wait for the TUI to be ready before pasting.
7. **Wire it up.** `remain-on-exit on` keeps the transcript after the agent exits. The script sets `@agent` and `@parent`, links both ways, and refreshes labels.

Sub agents always start in auto mode: `--permission-mode auto` for Claude and `-c approvals_reviewer="auto_review"` for Codex. Before this, a spawned codex-2nd fell back to its config default (`user`) and asked about every command, while its parent had been switched to auto review by hand.

For `codex` and `codex-2nd`, `--run` also passes `-c shell_environment_policy.set.{TMUX_PANE,TMUX,TMUX_AGENTS_DEPTH}` with the new pane's values, so commands the sub agent runs through Codex's shared daemon see its own identity and depth. `codex sandbox` confirmed the override is applied.

`--run` puts `~/.bin/tmux` first on `PATH`, because the tmux server's environment may predate the fish PATH change. For `codex-2nd` it sets `CODEX_HOME=~/.codex-2nd` rather than calling the fish function, which isn't available to bash.

### Browsing: `tmux-agents`

- **List.** One row per sub agent (panes with `@parent`), deduped. `ctrl-a` toggles to every named pane. fzf exports `FZF_PROMPT` to reloads, so `--list` reads the prompt (`agents> ` or `all> `) to know which view to rebuild; the toggle uses `transform` under `--with-shell 'bash -c'`, because the user's `$SHELL` is fish. The ID column is hidden with `--with-nth=2..` but still feeds `{1}` in the preview. The keys live in a two-line `--footer`, since both a header line and a one-line footer got truncated in the narrow list. Status is `#{?pane_dead,exited,#{?window_bell_flag,needs-you,running}}`. Parent names are looked up from `@parent`.
- **Preview.** fzf previews `capture-pane -ep -J -S -300` with `--preview-window follow`, so it shows the latest output in colour. A preview command runs once per cursor move, so on its own it's a still frame. To keep it live, fzf runs with `--listen` (a random localhost port, passed to its child commands as `FZF_PORT`; this fzf rejects a Unix socket path), and its `start` event launches `tmux-agents --preview-loop` in the background, which POSTs `refresh-preview` every `TMUX_AGENTS_PREVIEW_SECS` (0.5s) until the port closes with fzf.
- **Enter on a hidden agent.** The switcher itself runs in a popup, so it schedules a second popup with `run-shell -b "sleep 0.2; display-popup ..."` and exits. That popup runs `tmux-agents --view <pane>`, which attaches a nested client to the pane's session and selects its window. It unsets `TMUX` (required for nesting) but keeps the socket from `$TMUX` and passes `-S`. `prefix + d` detaches it; `--view` then runs the list again in the same popup with `--select <name>`, which puts the cursor back with `load:pos(N)+unbind(load)` (`start:pos` fires before the rows are read). `ctrl-a` runs `tmux-agents --toggle` through fzf's `transform`; it stores `@tmux_agents_list_mode` (`all` or `sub`) and returns the prompt and reload actions, so the list reopens in the last view.
- **Enter on a visible pane, or `ctrl-o`.** `switch-client -c <client> -t <pane>`.
- **`ctrl-x`.** Runs `tmux-dismiss`, then fzf reloads the list.

### Done state and cleanup

- **Marking.** `tmux-ask` sets `@state done` on the sender when it replies to its own `@parent`, and `@state working` on the receiver of any request.
- **Precedence.** The list shows `exited` > `done` > `needs-you` > `running`. Codex rings the bell at the end of every turn, so `needs-you` alone doesn't mean the task finished.
- **Cleanup.** `tmux-dismiss --done` lists done and exited sub agents, asks y/N on the terminal, and kills them. The switcher runs it with fzf `execute` on `ctrl-d`, then reloads.

### Closing, and telling the parent

- **Parents close their own.** `tmux-dismiss --from ME <name>` checks the target's `@parent` is ME and refuses otherwise. Permissions allow only this `--from` form: `Bash(tmux-dismiss --from:*)` and `prefix_rule(["tmux-dismiss", "--from"])`. Plain `tmux-dismiss` and `--done` stay with the user.
- **Passive notice.** Before killing a pane, `note_closed` appends its name to every peer's `@closed`, skipping the pane doing the closing. Nobody is interrupted. `resolve_peer` turns a lookup of a closed name into "was closed by the user" with advice to respawn, and `tmux-peers` lists them. `add_peer` drops a name from `@closed` once a live pane with that name is connected again. Pushing a notice into the parent was rejected, because every pasted message starts a new turn.

### Long messages

- **Convention.** The skill asks for a 3 to 5 line summary plus a file path whenever an answer runs past about 20 lines. Claude writes to its session scratchpad; other agents write to `$TMPDIR/tmux-agents/<name>/`.
- **Safety net.** Messages over `TMUX_ASK_MAX_LINES` (default 60) are written to `$TMPDIR/tmux-agents/<sender>/<time>-to-<receiver>.md`. Only the first 15 lines and the path are pasted, which keeps huge pastes out of TUIs.

### Status chip

- **Placement.** tmux can't float a widget over the panes without stealing focus (popups are modal), so the chip is a second status line. `tmux-agents --chip-layout on` (run by `tmux-spawn`) saves the user's `status-format[0]` in `@tmux_agents_main_format`, moves it to `status-format[1]`, puts the chip in `status-format[0]` (the chip itself emits `#[align=centre]`; left focus with right counts, and the whole line right-aligned, were tried first) and sets `status 2`. When `--chip` finds no sub agents it runs `--chip-layout off`, which restores the user's line and `status on`. `status-interval 1` keeps the spinner moving.
- **Frame rate.** tmux re-runs `#()` at most once a second (`status-interval` is whole seconds), so a smooth spinner needs a push model. With `@tmux_agents_chip_fps` above 1 (default 10), `status-format[0]` is `#{@chip}`, and `chip_layout` starts `tmux-agents --chip-daemon` with `run-shell -b`, one per server (`@tmux_agents_chip_pid`). The daemon rebuilds the chip once a second with `CHIP_SPIN=@@SPIN@@`, and every frame swaps in the next spinner character, sets `@chip` and runs `refresh-client -S` for each client. It exits when `status-format[0]` no longer shows `@chip`, which happens when the last sub agent is gone. The daemon runs with `errexit` off and logs to `/tmp/tmux-agents-<uid>/chip-daemon.log`: under the script's `set -e`, one failed `refresh-client` (a client detaching mid-loop) killed it, and the chip froze on a stale frame. `status-format[0]` also carries `#(tmux-agents --chip-ensure)`, which prints nothing and restarts the daemon within a second if it died. Daemons that start in the same second register their pid, wait 0.3s, and all but the last one registered exit. With fps 1, `status-format[0]` is `#(tmux-agents --chip)` as before. Measured around 8 to 9 frames a second at 10, because each frame's tmux calls add to the sleep.
- **Content.** First a focus agent that rotates every 4s through all sub agents, or only through those waiting for permission if any. Then per-project counts (`⠹` working, `✓` done, `⚠` needs permission, `✗` exited). Those render white on red, with `blink` once `@perm_since` is older than `TMUX_AGENTS_BLINK_SECS` (60s). Projects drop `agents-`/`projects-` and cap at 10 characters; task names over 18 keep their start and end around `…`.
- **Data, not screen scraping.** A first version parsed `capture-pane` output (Claude's spinner and `⏺ Tool(...)` lines, Codex's `• Working` and `• Ran` lines). It was dropped as brittle across TUI versions. Now:
  - `@activity`: the sub agent reports a few words with `tmux-agent-report --from ME "..."`. `tmux-spawn` adds the instruction to every task, and the skill repeats it.
  - `@perm_since`: hooks report permission waits, since a blocked agent can't.
    - **Claude:** `tmux-spawn --run` passes `--settings` with `Notification` (`permission_prompt`) → `--perm on --pane <id>` and `PostToolUse`/`UserPromptSubmit`/`Stop` → `--perm off`. Claude runs hooks in its own process and doesn't ask to trust them, so the pane id can sit in the command.
    - **Codex:** no hooks. Sub agents run with `approvals_reviewer = "auto_review"`, so every `require_escalated` request goes to a review model, and a rejection goes back to the agent, which asks the user in conversation if it must. The user never gets an approval prompt. An earlier version hooked `PermissionRequest` and turned the chip red on every escalation. The review approved within seconds, but in Codex's code mode the inner command often fired no `PostToolUse`, so the flag stayed until the turn's `Stop`: a sub agent running tests showed NEEDS PERMISSION for minutes with nothing to approve. Dropping the hooks also removed Codex's "hooks are new or changed" trust prompt, which had stopped every new sub agent. Along the way: Codex records hook trust against a hash of the command (so per-pane commands meant a prompt per agent), and hooks don't get `shell_environment_policy` (a `codex exec` probe saw the process's own `TMUX_PANE`); the hook input does carry `session_id`, and `UserPromptSubmit` the prompt text, if hooks are ever needed again.
  - `@state done`: set by the reply to the parent.
  - `@state needs_you`: a turn ended with the agent neither done nor waiting on anyone. This is how a Codex sub agent asks the user for something, since with `auto_review` it never shows an approval prompt and is told to explain what got blocked and ask. `tmux-agent-report --turn-end` decides: done stays done; if the agent has live sub agents that aren't done, or names in `@awaiting` (people it sent requests to and hasn't heard back from), it shows `waiting for ...` and stays working, because the skill tells agents to end their turn after delegating. The same goes for background work: `tmux-agent-report --waiting "<phrase>"` stores `@waiting_on` (cleared by the next normal report or turn start), and for Claude `claude_background` counts the pane's claude process's children started through Claude's shell snapshot (`/.claude/shell-snapshots/`), excluding the hook's own ancestors. At `Stop` no foreground command is running, so any such child is a background task; this caught a Claude waiting on a background test run that was showing needs you. Codex's background terminals run in its shared daemon and can't be attributed, so Codex relies on `--waiting`. Otherwise it sets `needs_you` and `@attention_since`. It's cleared by a progress report, an incoming request, or Claude's `UserPromptSubmit` (`--turn-start`).
    - **Turn ends.** Claude: the `Stop` hook. Codex: `notify` (not a hook, so no trust prompt). It receives JSON with `thread-id` and the turn's `input-messages`, checked with a `codex exec` probe; it runs with the daemon's environment like hooks do. The first message is the spawn request `[request from X to NAME via tmux-ask]`, so `--codex-notify` stores the thread id on NAME's pane (`@codex_thread`) and finds the pane by it on later turns. This replaces the user's own `notify` for sub agents only.
    - **`@awaiting`.** `tmux-ask` adds the receiver's name to the sender's `@awaiting` on a request and removes it from the receiver's side on a reply; names of closed panes are dropped at turn end.

### Alerts

The `alert-bell[42]` hook runs `tmux-agents --alert #{session_name} #{window_name}`. For sessions named `agents-*`, it shows `agent <name> needs you (prefix + a)` for 5s on every client that isn't itself viewing an agents session. Bells in unattached sessions still set `window_bell_flag` and fire the hook, which was verified.

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

The shipped fix is `~/.codex/rules/tmux-agents.rules`, which allows `tmux-ask`, `tmux-peers`, `tmux-peek` and `tmux-spawn` with `prefix_rule(..., decision="allow")`. `codex execpolicy check` confirms the decision, including absolute paths via `--resolve-host-executables`.

**Unverified:** whether an allow rule alone also runs the command outside the sandbox in a live session. The Codex skill keeps a fallback: request escalated permissions.

### Permissions

- Claude: `tmux-ask`, `tmux-peers`, `tmux-peek` and `tmux-spawn` (bare and `~/.bin/tmux/` forms) are allowlisted in `~/.claude/settings.json`. The Codex rules file allows the same four.
- `tmux-connect`, `tmux-disconnect`, plain `tmux-dismiss` and `--done` are deliberately not allowlisted. Connecting panes and closing other agents' transcripts are the user's call. Only `tmux-dismiss --from` is allowed, and it checks ownership.

### Where things are installed

| Piece | Location |
| --- | --- |
| Scripts | `~/.bin/tmux/`, on `PATH` via `.config/fish/config.fish` |
| Bindings and hooks | `~/.tmux.conf`: `prefix + A` connect, `prefix + a` agents; `pane-exited[42]` and `after-kill-pane[42]` run `tmux-peers --refresh`; `alert-bell[42]` runs `tmux-agents --alert`; `pane-mode-changed[42]` runs `tmux-ask --kick` |
| Agent instructions | Claude memory `prefer-tmux-agents`, `~/.codex/AGENTS.md` |
| Codex launch wrappers | `.config/fish/functions/{codex,codex-2nd,__codex_tmux_pins}.fish` |
| Skills | `~/.claude/skills/tmux-agents/`, `~/.codex/skills/tmux-agents/` |
| Codex rules | `~/.codex/rules/tmux-agents.rules` |

`~/.codex-2nd/` symlinks the Codex skill and `AGENTS.md` with relative links. The rules file is a **hard link** instead (see pitfalls).

## Pitfalls found while building

- **`display-popup` doesn't expand `#{...}` in its command.** A literal `#{pane_id}` reached `sh`, where `#` starts a comment, so the command silently lost its arguments. Wrap it in `run-shell`, which does expand formats. Use `-b` so the command queue isn't blocked while the popup waits for input.
- **`display-message -t %99 '#{pane_id}'` exits 0 with empty output for a closed pane.** `pane_alive` checks `list-panes -a` instead.
- **`set -o pipefail` plus `grep -q`.** `grep` exits early, the writer gets SIGPIPE, and the pipeline "fails". Capture output into a variable before grepping (`is_peer`, `pane_alive`).
- **Grouped sessions** duplicate panes in `list-panes -a`. Dedupe by id.
- **New windows run through fish, and `config.fish` reorders `PATH`.** A test put fake agents first on the server's `PATH`, but fish moved `~/.local/bin` ahead of them, so the real `claude` started with the test task. It was killed within about a second. `TMUX_SPAWN_BIN` is now the test hook: `--run` prepends it after fish has run.
- **Nested `tmux attach` after `unset TMUX` goes to the default socket.** On a `-L` test server it attached to the user's real server. `--view` passes `-S` with the socket taken from `$TMUX`.
- **`read` with `IFS=<tab>` collapses empty fields**, because tab is IFS whitespace. An empty `@parent` shifted every later column. Formats emit `-` for empty values.
- **`basename ... | tr -c` also translates the trailing newline** into the replacement character. Sanitize `"$(basename ...)"` through `printf '%s'` instead.
- **`send-keys` goes to copy mode.** If the user is scrolling the receiver's pane, `paste-buffer` still reaches the program (it bypasses modes) but `send-keys Enter` is handled by copy mode, so the message sat in the input box unsent. Pasting a raw `\r` instead worked for `cat` but not for Claude Code, whose input didn't submit on it. So `user_busy` counts `#{pane_in_mode}` as busy: someone scrolling a pane is reading it, and the message is queued until they leave copy mode.
- **Chained commands run in Codex's sandbox.** Prefix allow rules only match a command's start, so `echo ...; tmux-peers` ran sandboxed, and tmux reported the blocked socket as "no tmux server running". `require_tmux` now says what happened when `$TMUX` is set, and the skill says to run `tmux-*` commands on their own.
- **`grep -v` that filters out every line exits 1.** Under `pipefail` and `set -e`, removing the only name from `@closed` silently killed `tmux-spawn` halfway through linking. Use `awk` for filters that can come out empty.
- **Codex runs shell commands in a shared app-server daemon**, one per `CODEX_HOME`, which keeps the environment of the pane it was started from. A codex-2nd sub agent in `%40` ran `tmux-ask` with `TMUX_PANE=%36` (its parent's pane), so it acted as its parent and got "not connected". `ps eww` showed the TUI with `%40` and the daemon with `%36`. The main Codex daemon has no `TMUX_PANE` at all. The fixes are `--from` identity in every message, plus `shell_environment_policy.set` pins (`TMUX_PANE`, `TMUX`, `TMUX_AGENTS_PINNED=1`) for every Codex started in tmux: `tmux-spawn --run` adds them for sub agents, and the fish functions `codex` and `codex-2nd` add them (via `__codex_tmux_pins`) for Codex the user starts. A top-level codex-2nd started without them ran `tmux-peers`, saw its parent's identity, asked the user to confirm that name, got a "yes", and messaged another project's agent as someone else. So the skill no longer lets an unpinned Codex pick a name from `tmux-peers` or have the user confirm one, and `tmux-peers` prints a warning when neither `--from`, `TMUX_AGENTS_PINNED` nor `CLAUDECODE` is set. Verified live: a codex-2nd restarted through the wrapper saw `TMUX_AGENTS_PINNED=1` and `you: codex-~-1 (%48)` while sharing the daemon started from `%36`. `TMUX_AGENTS_DEPTH` had the same problem, which silently broke the depth limit for Codex.
- **Codex silently ignores symlinked `.rules` files** ([openai/codex#32658](https://github.com/openai/codex/issues/32658), open): `collect_policy_files()` keeps only `is_file()` entries. The codex-2nd symlink was skipped, so codex-2nd prompted for `tmux-peers`; its log shows the `CommandExecutionRequestApproval`. `~/.codex-2nd/rules/tmux-agents.rules` is now a hard link. An editor that saves by writing a new file and renaming it (including `sed -i`) breaks the link; recreate it with `ln -f ~/.codex/rules/tmux-agents.rules ~/.codex-2nd/rules/`.
- **Prefix allow rules may still prompt for sandbox escapes** ([openai/codex#15298](https://github.com/openai/codex/issues/15298), reported on Windows). If Codex still asks, approving with "don't ask again" writes a rule to that account's `default.rules`, which works.
- **Font ligatures** can render `-~-` as an arrow (`claude-~-1` shows as `claude⤳1`). This is cosmetic only.

## Testing

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
- A Codex started without the fish wrappers (e.g. `command codex`, another shell, or the desktop app) still can't know its own name until it receives a message. The skill tells it to ask the user for its pane's name.
- Viewing a hidden agent attaches a second client to its session, which resizes that session's windows to the popup.
- `@peer_names` is a cache. Renaming a pane by hand (`set -p @agent`) needs `tmux-peers --refresh`.

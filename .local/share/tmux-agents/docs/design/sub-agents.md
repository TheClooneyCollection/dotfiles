# Sub agents

Part of the [design notes](../../DESIGN.md).

Agents are told (skill, Claude memory, `~/.codex/AGENTS.md`) to use `tmux-spawn` wherever they would use a built-in sub agent. Built-in subagents can't be switched off, so this is an instruction, not enforcement.

## Spawning

1. **Refuse if too deep.** `TMUX_AGENTS_DEPTH` (unset means 0) must be below `TMUX_AGENTS_MAX_DEPTH` (default 2). The child gets depth + 1 through `new-window -e`, so a top-level agent can spawn children, and they can spawn grandchildren, which can't spawn further.
2. **Pick the agent kind.** An explicit `claude`, `codex` or Codex profile wins. Profiles are extra Codex accounts in `TMUX_AGENTS_CODEX_HOMES` (`name=CODEX_HOME ...`). Otherwise, in order:
   - `TMUX_AGENTS_KIND`, pinned by `tmux-spawn` and the Codex wrappers, since Codex runs commands without its own `CODEX_HOME`;
   - `CLAUDECODE` means claude;
   - a `CODEX_HOME` listed as a profile means that profile;
   - the caller pane's `pane_current_command`.
3. **Name the caller** with `suggest_name` if it has no name, so the child can reply.
4. **Name the child.** `--name` is sanitized and made unique with `unique_name` (`-2`, `-3`, ...). Without it, `name_for <agent> <cwd>` gives `claude-<dir>-<N>`.
5. **Pick the session.** It is `agents-<project>`, from `agents_session_for`: the git root's basename, `home` for `$HOME`, else the directory's basename. It is created with `new-session -d` on first use. One window per sub agent.
6. **Hand over the task through a file.** The request body goes to a `mktemp` file. The window runs `tmux-spawn --run <agent> <file>`, which reads and deletes it and `exec`s the agent with the text as its first prompt (`claude "<prompt>"` and `codex "<prompt>"` both start interactive with an initial prompt). No shell ever quotes the task, and nothing has to wait for the TUI to be ready before pasting.
7. **Wire it up.** `remain-on-exit on` keeps the transcript after the agent exits. The script sets `@agent` and `@parent`, links both ways, and refreshes labels.

What `--run` sets up:

- **Auto mode.** Sub agents always start with `--permission-mode auto` (Claude) or `-c approvals_reviewer="auto_review"` (Codex). Before this, a spawned Codex on a second account fell back to its config default (`user`) and asked about every command, while its parent had been switched to auto review by hand.
- **Codex identity pins.** For Codex (any profile), `--run` passes `-c shell_environment_policy.set.{TMUX_PANE,TMUX,TMUX_AGENTS_DEPTH}` with the new pane's values, so commands the sub agent runs through Codex's shared daemon see its own identity and depth. `codex sandbox` confirmed the override is applied. See [environment](environment.md#codex-runs-commands-in-a-shared-daemon).
- **PATH.** `--run` puts the scripts' own directory first on `PATH`, because the tmux server's environment may predate the user's PATH setup.
- **Profiles.** For a profile it exports that profile's `CODEX_HOME`, and `TMUX_AGENTS_CODEX_HOMES` is passed to the new window with `-e`.

## Browsing: `tmux-agents`

- **List.** One two-line entry per sub agent (panes with `@parent`), deduped: name, status and parent, then what it is doing (`@activity`, or "no report yet") dimmed underneath, so long activities stay readable. Entries are grouped into a section per project, marked by a `▸ project` line on the first entry of each; a hidden agent's project comes from its `agents-<project>` session, any other pane's from its directory, the way `tmux-spawn` picks it. Sections sort by their most urgent agent. Every entry starts with its pane id (hidden by `--with-nth=2..`), so `{1}` is the pane even on a section's first entry. Entries are separated by `\036` inside the script (bash strings can't hold NUL) and turned into NUL for `fzf --read0`. `ctrl-a` toggles to every named pane. Parent names are looked up from `@parent`. Status is the same as the chip's: `✗ exited`, else `⚠ permission` (`@perm_since` set), else `@state` (`◆ needs you`, `✓ done`, or `⠿ working`). Rows that need the user sort first.
- **List mechanics.** fzf exports `FZF_PROMPT` to reloads, so `--list` reads the prompt (`agents> ` or `all> `) to know which view to rebuild. `ctrl-a` runs `tmux-agents --toggle` through fzf's `transform` under `--with-shell 'bash -c'` (the user's `$SHELL` is fish); it stores `@tmux_agents_list_mode` (`all` or `sub`) and returns the prompt and reload actions, so the list reopens in the last view. The ID column is hidden with `--with-nth=2..` but still feeds `{1}` in the preview. The keys live in a two-line `--footer`, since both a header line and a one-line footer got truncated in the narrow list.
- **Preview.** fzf previews `capture-pane -ep -J -S -300` with `--preview-window follow`, so it shows the latest output in colour. A preview command runs once per cursor move, so on its own it's a still frame. To keep it live, fzf runs with `--listen` (a random localhost port, passed to its child commands as `FZF_PORT`; this fzf rejects a Unix socket path), and its `start` event launches `tmux-agents --preview-loop` in the background, which POSTs `refresh-preview` every `TMUX_AGENTS_PREVIEW_SECS` (0.5s) until the port closes with fzf.
- **Enter on a hidden agent.** The switcher runs in a popup, so it schedules a second popup with `run-shell -b "sleep 0.2; display-popup ..."` and exits. That popup runs `tmux-agents --view <pane>`, which attaches a nested client to the pane's session and selects its window. It unsets `TMUX` (required for nesting) but keeps the socket from `$TMUX` and passes `-S`.
- **Back to the list.** `prefix + d` detaches the nested client; `--view` then runs the list again in the same popup with `--select <name>`, which puts the cursor back with `load:pos(N)+unbind(load)` (`start:pos` fires before the rows are read).
- **`prefix + d` in the list** closes it. fzf can't bind a two-key chord, so this is two bindings: the prefix key (read from tmux's `prefix`, e.g. `ctrl-b`) stores `@tmux_agents_prefix_at`, and `d` runs `tmux-agents --prefix-d`, which answers `abort` if the prefix came within 2s and `put(d)` (type a d) otherwise.
- **Enter on a visible pane, or `ctrl-o`.** `switch-client -c <client> -t <pane>`.
- **`ctrl-x`.** Runs `tmux-dismiss`, then fzf reloads the list.

## Done state and cleanup

- **Marking.** `tmux-ask` sets `@state done` on the sender when it replies to its own `@parent`, and `@state working` on the receiver of any request.
- **Cleanup.** `tmux-dismiss --done` lists done and exited sub agents, asks y/N on the terminal, and kills them. The switcher runs it with fzf `execute` on `ctrl-d`, then reloads.
- **Requests reopen work; notices don't.** A request to a `done` sub agent sets it back to `working` and adds it to the sender's `@awaiting`; a notice changes neither. Seen live: a parent broadcast a rule ("no reply needed, don't restart") to finished sub agents as a request. They acknowledged locally without `--reply`, and the next turn end marked them needs you, while the parent kept waiting on them. The skill now says to send information as notices. Notices also leave a Claude sub agent's state alone at turn start (the `UserPromptSubmit` hook sees the prompt begin with `[notice from`): otherwise a notice would clear what it reported with `--waiting`, and the turn end after it would mark it needs you. Guessing from the answer's wording ("standing by") was rejected, since it would also hide real unfinished work.

## Closing, and telling the parent

- **Parents close their own.** `tmux-dismiss --from ME <name>` checks the target's `@parent` is ME and refuses otherwise. Permissions allow only this `--from` form: `Bash(tmux-dismiss --from:*)` and `prefix_rule(["tmux-dismiss", "--from"])`. Plain `tmux-dismiss` and `--done` stay with the user.
- **Passive notice.** Before killing a pane, `note_closed` appends its name to every peer's `@closed`, skipping the pane doing the closing. Nobody is interrupted. `resolve_peer` turns a lookup of a closed name into "was closed by the user" with advice to respawn, and `tmux-peers` lists them. `add_peer` drops a name from `@closed` once a live pane with that name is connected again. Pushing a notice into the parent was rejected, because every pasted message starts a new turn.
- **Session records.** Pane options die with the pane, so reopening needs a record that outlives it: one file per sub agent name in `${XDG_STATE_HOME:-~/.local/state}/tmux-agents/<server socket>/sessions/`, `key=value` lines `kind`, `id`, `dir`, `parent` (a name, since pane ids don't survive), `depth` and `closed` (epoch, set by `tmux-dismiss`). Per server, like the message queue, because names and pane ids are per server. A new spawn with the same name replaces the record.
- **Session ids.** Claude takes an id up front: `tmux-spawn` generates a UUID and starts it with `--session-id`. Codex can't, so its id is the `thread-id` from its first `agent-turn-complete` notify (the session-title side thread is already filtered out), which `tmux-agent-report` writes into the record. A Codex closed before its first turn ends has no id and can't be reopened.
- **Reopening.** `tmux-spawn --resume NAME` opens a new window in the project's session from the record and runs `claude --resume ID` or `codex resume ID` with the same auto mode, hooks, pins and depth, then names it, connects it to the caller (or `--parent`, which the list passes), drops it from the parent's `@closed`, sets `@codex_thread` for notify, and marks it `done` (idle, not needs you). It refuses names that are still open.
- **Closed in the list.** `closed_agents` adds a row per record whose name has no live pane, closed within `TMUX_AGENTS_RESUME_DAYS` (default 7; older records are deleted when the list is built), in a last `closed (N) · enter reopens` section, newest first. All of them are listed rather than the latest few, so typing a name always finds one. Their id column is `closed:NAME`; the preview shows the record, `ctrl-x` (`tmux-agents --dismiss`) deletes it, and Enter or `ctrl-o` runs `tmux-spawn --resume` first and then opens the new pane like any other.

## Status chip

### Placement

tmux can't float a widget over the panes without stealing focus (popups are modal), so the chip is a second status line.

- `tmux-agents --chip-layout on` (run by `tmux-spawn`) saves the user's `status-format[0]` in `@tmux_agents_main_format`, moves it to `status-format[1]`, puts the chip in `status-format[0]` and sets `status 2`.
- The chip emits `#[align=centre]` itself. Left focus with right counts, and the whole line right-aligned, were tried first.
- When the chip finds no sub agents it runs `--chip-layout off`, which restores the user's line and `status on`.
- `status-interval 1` keeps the spinner moving.

### Frame rate

tmux re-runs `#()` at most once a second (`status-interval` is whole seconds), so a smooth spinner needs a push model.

- With `@tmux_agents_chip_fps` above 1 (default 10), `status-format[0]` is `#{@chip}`, and `chip_layout` starts `tmux-agents --chip-daemon` with `run-shell -b`, one per server (`@tmux_agents_chip_pid`).
- The daemon rebuilds the chip once a second with `CHIP_SPIN=@@SPIN@@`. Every frame swaps in the next spinner character, sets `@chip` and runs `refresh-client -S` for each client. Measured around 8 to 9 frames a second at 10, because each frame's tmux calls add to the sleep.
- It exits when `status-format[0]` no longer shows `@chip`, which happens when the last sub agent is gone.
- It runs with `errexit` off and logs to `/tmp/tmux-agents-<uid>/chip-daemon.log`. Under the script's `set -e`, one failed `refresh-client` (a client detaching mid-loop) killed it, and the chip froze on a stale frame.
- `status-format[0]` also carries `#(tmux-agents --chip-ensure)`, which prints nothing and restarts the daemon within a second if it died. Daemons that start in the same second register their pid, wait 0.3s, and all but the last one registered exit.
- With fps 1, `status-format[0]` is `#(tmux-agents --chip)`, re-run by tmux each second.

### Content

- **Focus.** One agent, rotating every 4s through all sub agents, or only through those that need the user (permission or needs you) if any. Permission waits render white on red, needs you black on amber (`colour214`). Either gets `blink` once it has waited longer than `TMUX_AGENTS_BLINK_SECS` (60s), counted from `@perm_since` or `@attention_since`.
- **Counts.** Per project: `⚠` needs permission, `◆` needs you, `⠹` working (the spinner), `✓` done, `✗` exited.
- **Shortening.** Projects drop `agents-`/`projects-` and cap at 10 characters. Task names over 18 characters keep their start and end around `…`.

### Data, not screen scraping

A first version parsed `capture-pane` output (Claude's spinner and `⏺ Tool(...)` lines, Codex's `• Working` and `• Ran` lines). It was dropped as brittle across TUI versions. Now the chip reads pane options:

- **`@activity`.** The sub agent reports a few words with `tmux-agent-report --from ME "..."`. `tmux-spawn` adds the instruction to every task, and the skill repeats it.
- **`@state done`.** Set by the reply to the parent.
- **`@perm_since`.** Hooks report permission waits, since a blocked agent can't.
  - **Claude:** `tmux-spawn --run` passes `--settings` with `Notification` (`permission_prompt`) → `--perm on --pane <id>`, and `PostToolUse`/`UserPromptSubmit`/`Stop` → `--perm off`. Claude runs hooks in its own process and doesn't ask to trust them, so the pane id can sit in the command.
  - **Codex:** no hooks. Sub agents run with `approvals_reviewer = "auto_review"`, so every `require_escalated` request goes to a review model, and a rejection goes back to the agent, which asks the user in conversation if it must. The user never gets an approval prompt.
  - **Why Codex has no hooks.** An earlier version hooked `PermissionRequest` and turned the chip red on every escalation. The review approved within seconds, but in Codex's code mode the inner command often fired no `PostToolUse`, so the flag stayed until the turn's `Stop`: a sub agent running tests showed NEEDS PERMISSION for minutes with nothing to approve. Dropping the hooks also removed Codex's "hooks are new or changed" trust prompt, which had stopped every new sub agent. Notes if hooks are ever needed again: Codex records hook trust against a hash of the command (so per-pane commands meant a prompt per agent); hooks don't get `shell_environment_policy` (a `codex exec` probe saw the process's own `TMUX_PANE`); the hook input does carry `session_id`, and `UserPromptSubmit` carries the prompt text.
- **`@state needs_you`.** A turn ended with the agent neither done nor waiting on anyone. This is how a Codex sub agent asks the user for something: with `auto_review` it never shows an approval prompt, and it is told to explain what got blocked and ask. `tmux-agent-report --turn-end` decides:
  - done stays done;
  - if the agent has live sub agents that aren't done, or names in `@awaiting` (requests it sent without a reply yet), it shows `waiting for ...` and stays working, because the skill tells agents to end their turn after delegating;
  - the same goes for background work. `tmux-agent-report --waiting "<phrase>"` stores `@waiting_on`, cleared by the next normal report or turn start. For Claude, `claude_background` also counts the children of the pane's claude process that were started through Claude's shell snapshot (`/.claude/shell-snapshots/`), excluding the hook's own ancestors. At `Stop` no foreground command is running, so any such child is a background task; this caught a Claude waiting on a background test run that was showing needs you. Codex's background terminals run in its shared daemon and can't be attributed, so Codex relies on `--waiting`;
  - otherwise it sets `needs_you` and `@attention_since`.

  `needs_you` is cleared by a progress report, an incoming request, or Claude's `UserPromptSubmit` (`--turn-start`).
- **Turn ends.** Claude: the `Stop` hook. Codex: `notify`, which is not a hook, so there is no trust prompt. It receives JSON with `thread-id` and the turn's `input-messages` (checked with a `codex exec` probe), and runs with the daemon's environment like hooks do. The first message is the spawn request `[request from X to NAME via tmux-ask]`, so `--codex-notify` stores the thread id on NAME's pane (`@codex_thread`) and finds the pane by it on later turns. This replaces the user's own `notify` for sub agents only.
- **`@awaiting`.** `tmux-ask` adds the receiver's name to the sender's `@awaiting` on a request and removes it from the receiver's side on a reply. Names of closed panes are dropped at turn end.

## Alerts

The `alert-bell[42]` hook runs `tmux-agents --alert #{session_name} #{window_name}`. For sessions named `agents-*`, it shows `agent <name> needs you (prefix + a)` for 5s on every client that isn't itself viewing an agents session. Bells in unattached sessions still set `window_bell_flag` and fire the hook, which was verified. Codex rings the bell at the end of every turn, so a bell alone doesn't mean the task finished or that the agent is blocked.

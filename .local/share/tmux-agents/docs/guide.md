# tmux-agents guide

The details behind the [README](../README.md). Design notes and pitfalls are in [DESIGN.md](../DESIGN.md).

## Connecting agents

1. Open a pane and start `claude`.
2. Open another pane and connect it before starting Codex:
   ```sh
   tmux-connect --as codex   # pick the claude pane from the list, name it "claude"
   codex
   ```
3. Tell either agent to talk to the other: "ask codex to review this diff".

Or skip connecting by hand: tell an agent "connect codex and have it do xyz". It runs `tmux-connect --from <itself> codex`, which finds the other pane in this window running codex, names both panes if needed, and links them; then it sends the task.

Both agents already running? Press `prefix + A` in one pane to connect it from a popup. It lists this window's panes with a preview; `ctrl-a` switches to every window, grouped by window, and is remembered.

**Agents in other windows.** Tell an agent "connect the codex in stone-age" or "connect the claude in window 2". It runs `tmux-connect --from <itself> codex@stone-age` (a project, by name or part of it) or `claude@2` (a window; `work:2` for another session). For anything vaguer it lists every pane with `tmux-connect --list` and picks the one you mean, or asks. The agent in the other window gets a short notice saying who connected, since it didn't see it happen.
Add more agents the same way. Links are one-to-one: A↔B and B↔C does not link A↔C.

Connected panes show `name ⇄ peers` on their top border, e.g. `claude ⇄ codex, gemini`.

Suggested names are `<command>-<dir>-<N>`: `claude-project-xyz-1`, `claude-~-1` in home, then `-2`, `-3`... Both panes are named in one form: ↑/↓ to switch, type to edit, Enter to accept.

## Sub agents

Agents start sub agents with `tmux-spawn` instead of their built-in ones, so every sub agent has a real pane with its full history.

```
claude:  tmux-spawn --name auth-review "review src/auth.ts"
         → new hidden window "auth-review" in session agents-<project>
         → starts claude with the task, connected to the caller
auth-review:  ...works, then tmux-ask --reply back to the caller
```

- **Hidden by default.** Each project gets its own session (`agents-api`, `agents-blog`), one window per sub agent. Nothing is added to your layout.
- **Easy to check.** `prefix + a` opens `tmux-agents`: your sub agents with status, parent, project, what they're doing now, and a preview that refreshes twice a second. Statuses use the chip's colours (red `⚠ permission`, amber `◆ needs you`, `⠿ working`, green `✓ done`, grey `✗ exited`), and the ones that need you sort to the top. The keys are shown in a footer.
  - `enter`: open a hidden agent in a popup, where you can approve prompts. `prefix + d` takes you back to the list, on the same agent. Visible panes are jumped to instead.
  - `ctrl-o`: jump there full screen; `prefix + L` jumps back. `ctrl-x`: dismiss. `ctrl-d`: close every `done`/`exited` sub agent after a y/N confirmation. `ctrl-a`: toggle between sub agents and every named pane (remembered for next time). `ctrl-r`: refresh. `prefix + d`: close the list (it also leaves an agent's popup, so pressing it twice gets you all the way out).

- **Status chip.** While sub agents exist, a line above the status bar shows them:

  ```
        ⠹ auth-review: reading src/auth.ts  │  api ⠹ 2 ✓ 1 · blog ⠹ 1
  ```
  Centred: one agent in focus, rotating every 4s, then per-project counts (`⠹` working, `✓` done, `⚠` needs permission, `◆` needs you, `✗` exited). An agent waiting for permission (red) or for you (amber) takes over the focus, and blinks after 60s unanswered. **Needs you** means a sub agent ended its turn without replying to its parent and without waiting on anyone or anything (its own sub agents, requests it sent, background work it reported with `tmux-agent-report --waiting`, or, for Claude, Bash commands still running in the background), which is how a Codex sub agent asks you for something (it never gets approval prompts, see [sub agents](design/sub-agents.md#data-not-screen-scraping)). The line disappears when the last sub agent is closed. It animates at `@tmux_agents_chip_fps` frames a second (default 10, set after the `source-file` line to change it); `1` falls back to tmux's once-a-second refresh.
- **Progress reports.** Sub agents report what they're doing with `tmux-agent-report "<a few words>"`; permission waits are reported by hooks. Nothing is read off the screen.
- **Done.** A sub agent is `done` once it replies to its parent, and `running` again when it gets a new request.
- **Long answers.** Agents reply with a short summary and a path to the full report in a temp dir. `tmux-ask` also saves any message over 60 lines to `$TMPDIR/tmux-agents/<sender>/` and sends the first 15 lines plus the path.
- **Alerts.** When a hidden agent rings the bell (e.g. waiting for approval), your status line says `agent <name> needs you`.
- **History is kept** until someone closes it. Panes stay after the agent exits. The parent closes its sub agents once it has what it needs (`tmux-dismiss --from`, own sub agents only); you can close any of them.
- **Parents learn about your closes.** When you close a sub agent, its parent isn't interrupted. Its `tmux-peers` lists it under `closed by user`, and a later `tmux-ask` says it was closed instead of failing with "no pane".
- **Reopening.** A closed sub agent can come back with its whole conversation for 7 days (`TMUX_AGENTS_RESUME_DAYS`). In the list they sit in a `closed` section at the bottom, newest first: `enter` reopens one connected to its old parent and opens it, `ctrl-o` reopens and jumps there, `ctrl-x` forgets it. Or ask the parent ("reopen auth-review"), which runs `tmux-spawn --resume auth-review`. A Codex sub agent can be reopened once it has finished a turn; that's when Codex reports its session id.
- **Same kind by default, in auto mode.** Claude spawns Claude, Codex spawns Codex, and a Codex on another account spawns on that account. Sub agents start with Claude's `--permission-mode auto` or Codex's `approvals_reviewer="auto_review"`.
- **Depth limit.** At most two levels of sub agents (`TMUX_AGENTS_MAX_DEPTH`).

## Commands

| Command | What it does |
| --- | --- |
| `tmux-connect [target] [--as NAME] [--all]`, `tmux-connect --from ME codex\|claude\|NAME` | Name this pane and link it to `target` (name, `%id`, or `1.0`). No target opens a picker of panes in this window (`--all`: every window); the pane under the cursor is tinted. Unnamed panes get asked for a name. With `--from` (agents) it never prompts: `codex`/`claude` picks that agent's pane in this window, and names are generated. |
| `tmux-disconnect [name]` | Unlink from `name`, or from everyone. |
| `tmux-peers` | Show this pane's name and its connections. |
| `tmux-ask [--from ME] [--any] <name> [--reply] [msg]` | Paste a message into a connected pane and submit it. Reads stdin if no `msg`. `--any` sends to any named pane, connected or not. |
| `tmux-peek <name> [lines]` | Print the last lines (default 40) of a connected pane. |
| `tmux-spawn [claude\|codex\|PROFILE] [--name NAME] [task]` | Start a connected sub agent in the project's hidden session and send it the task (or stdin). Taken names get `-2`, `-3`... |
| `tmux-agent-report [--from ME] "text"` | Report what a sub agent is doing, for the chip. |
| `tmux-agents` | Browse sub agents, or every named pane with `ctrl-a` (`prefix + a`). |
| `tmux-dismiss [--from ME] <name>` | Close an agent's pane and its transcript. With `--from`, only your own sub agents. `--done` closes every done/exited one after a y/N. |

## How messages flow

```
claude:  tmux-ask codex "review src/auth"      → pasted into codex's pane
codex:   ...works, you approve its prompts...
codex:   tmux-ask --reply claude <<'MSG' ...   → pasted into claude's pane
```

- Requests say who sent them, who they're for, and the exact reply command (with `--from <receiver>`). Replies say not to answer back, which stops loops.
- Nobody waits. The sender ends its turn, and the reply arrives later as a new prompt.
- **You typing wins.** If you pressed a key in the receiver's pane within the last 8 seconds, or are scrolling it (copy mode), the message is queued. It goes out as soon as you leave copy mode (mouse or keys), or after 8 quiet seconds if you were typing. A pane left in copy mode for 5 minutes without a key is taken out of it so the message goes through (`TMUX_ASK_COPY_IDLE_SECS`, `0` to turn it off). Queued messages keep their order. If the receiver's pane is gone, or you kept typing there for 30 minutes, the message is kept as a `.undelivered` file and your status line says where.
- **Messages are fenced.** Every message ends with `[end of request/reply from X to Y]`. If a draft of yours gets submitted along with one, the agent treats the text outside the markers as yours.
- If an agent is busy, Claude and Codex queue the pasted message themselves.

## How it works

State lives on the panes as tmux user options, with no files:

- `@agent`: the pane's name, unique across the tmux server.
- `@peers`: pane ids it links to.
- `@parent`: on sub agents, the pane that spawned them.

Pane ids survive moving panes between windows. Closing a pane drops its links.
Inspect with `tmux show -p @agent` / `tmux show -p @peers`.

Agent-facing commands take `--from <name>` to say who is acting. Codex runs commands in a shared daemon whose `$TMUX_PANE` may be another pane, so agents always pass it; see [the shared daemon](design/environment.md#codex-runs-commands-in-a-shared-daemon).

`TMUX_ASK_ENTER_DELAY` (default `0.5`) sets the pause between pasting and pressing Enter. Raise it if a TUI drops the Enter.
`TMUX_CONNECT_HIGHLIGHT` (default `bg=colour24`) sets the picker tint.
`TMUX_AGENTS_MAX_DEPTH` (default `2`) limits sub agent levels.

## More than one Codex account

List extra Codex homes as `name=path` pairs, then run `install.sh` again so they get the skill and rules too:

```sh
export TMUX_AGENTS_CODEX_HOMES="work=$HOME/.codex-work"
```

Putting the same line in `~/.tmux.conf` also works, and reaches agents that were already running when you set it:

```tmux
set-environment -g TMUX_AGENTS_CODEX_HOMES "work=$HOME/.codex-work"
```

`tmux-spawn work "task"` starts a sub agent on that account, and a Codex started with `CODEX_HOME=$HOME/.codex-work` spawns `work` sub agents by default. Give it its own wrapper; `integrations/sh/codex.sh` shows one.

# tmux agents

Connect AI agents (Claude, Codex, anything) running in tmux panes so they can message each other, and let them start sub agents in hidden panes. You watch every pane and approve permissions yourself.

Design notes, protocol details and known pitfalls: [DESIGN.md](DESIGN.md).

## Quick start

1. Open a pane and start `claude`.
2. Open another pane and connect it before starting Codex:
   ```sh
   tmux-connect --as codex   # pick the claude pane from the list, name it "claude"
   codex
   ```
3. Tell either agent to talk to the other: "ask codex to review this diff".

Both agents already running? Press `prefix + A` in one pane to connect it from a popup.
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

- **Hidden by default.** Each project gets its own session (`agents-dotfiles`, `agents-blog`), one window per sub agent. Nothing is added to your layout.
- **Easy to check.** `prefix + a` opens `tmux-agents`: your sub agents with status (`running`, `needs-you`, `done`, `exited`), parent, project and a live preview. The keys are shown in a footer.
  - `enter`: open a hidden agent in a popup, where you can approve prompts. `prefix + d` closes it. Visible panes are jumped to instead.
  - `ctrl-o`: jump there full screen; `prefix + L` jumps back. `ctrl-x`: dismiss. `ctrl-d`: close every `done`/`exited` sub agent after a y/N confirmation. `ctrl-a`: toggle between sub agents and every named pane. `ctrl-r`: refresh.
- **Status bar.** The right side shows `active subagents: N`, plus `· N needs you` and `· N done`.
- **Done.** A sub agent is `done` once it replies to its parent, and `running` again when it gets a new request.
- **Long answers.** Agents reply with a short summary and a path to the full report in a temp dir. `tmux-ask` also saves any message over 60 lines to `$TMPDIR/tmux-agents/<sender>/` and sends the first 15 lines plus the path.
- **Alerts.** When a hidden agent rings the bell (e.g. waiting for approval), your status line says `agent <name> needs you`.
- **History is kept** until someone closes it. Panes stay after the agent exits. The parent closes its sub agents once it has what it needs (`tmux-dismiss --from`, own sub agents only); you can close any of them.
- **Parents learn about your closes.** When you close a sub agent, its parent isn't interrupted. Its `tmux-peers` lists it under `closed by user`, and a later `tmux-ask` says it was closed instead of failing with "no pane".
- **Same kind by default.** Claude spawns Claude, Codex spawns Codex, codex-2nd spawns codex-2nd.
- **Depth limit.** At most two levels of sub agents (`TMUX_AGENTS_MAX_DEPTH`).

## Commands

| Command | What it does |
| --- | --- |
| `tmux-connect [target] [--as NAME] [--all]` | Name this pane and link it to `target` (name, `%id`, or `1.0`). No target opens a picker of panes in this window (`--all`: every window); the pane under the cursor is tinted. Unnamed panes get asked for a name. |
| `tmux-disconnect [name]` | Unlink from `name`, or from everyone. |
| `tmux-peers` | Show this pane's name and its connections. |
| `tmux-ask [--from ME] <name> [--reply] [msg]` | Paste a message into a connected pane and submit it. Reads stdin if no `msg`. |
| `tmux-peek <name> [lines]` | Print the last lines (default 40) of a connected pane. |
| `tmux-spawn [claude\|codex\|codex-2nd] [--name NAME] [task]` | Start a connected sub agent in the project's hidden session and send it the task (or stdin). Taken names get `-2`, `-3`... |
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
- **You typing wins.** If you pressed a key in the receiver's pane within the last 8 seconds, or are scrolling it (copy mode), the message is queued. It goes out as soon as you leave copy mode (mouse or keys), or after 8 quiet seconds if you were typing. Queued messages keep their order. If the receiver's pane is gone, or you kept typing there for 30 minutes, the message is kept as a `.undelivered` file and your status line says where.
- **Messages are fenced.** Every message ends with `[end of request/reply from X to Y]`. If a draft of yours gets submitted along with one, the agent treats the text outside the markers as yours.
- If an agent is busy, Claude and Codex queue the pasted message themselves.

## Setup

- `~/.bin/tmux` on PATH (in `.config/fish/config.fish`).
- **Start Codex from the fish wrappers** `codex` and `codex-2nd` (in `.config/fish/functions/`). Inside tmux they pin the pane's identity, so Codex's `tmux-*` calls act as the right pane (see DESIGN.md).
- `~/.tmux.conf`: `prefix + A` (connect), `prefix + a` (agents), the status-bar count, and hooks for border refresh, bell alerts and sending queued messages when you leave copy mode. Reload with `prefix + r`.
- Agents learn the protocol from the `tmux-agents` skill in `~/.claude/skills/` and `~/.codex/skills/` (`~/.codex-2nd/skills/` symlinks to the Codex one). Claude's memory and `~/.codex/AGENTS.md` tell them to use `tmux-spawn` for every sub agent.
- **Codex:** its sandbox blocks the tmux socket. `~/.codex/rules/tmux-agents.rules` allows `tmux-ask`, `tmux-peers`, `tmux-peek` and `tmux-spawn` without prompting (`codex-2nd` has a hard link to the same file: Codex ignores symlinked `.rules` files).
- **Claude:** `tmux-ask`, `tmux-peers`, `tmux-peek` and `tmux-spawn` are allowlisted in `~/.claude/settings.json`. So is `tmux-dismiss --from` (agents closing their own sub agents). `tmux-connect`, `tmux-disconnect` and plain `tmux-dismiss` stay yours and still prompt.

## How it works

State lives on the panes as tmux user options, with no files:

- `@agent`: the pane's name, unique across the tmux server.
- `@peers`: pane ids it links to.
- `@parent`: on sub agents, the pane that spawned them.

Pane ids survive moving panes between windows. Closing a pane drops its links.
Inspect with `tmux show -p @agent` / `tmux show -p @peers`.

Agent-facing commands take `--from <name>` to say who is acting. Codex runs commands in a shared daemon whose `$TMUX_PANE` may be another pane, so agents always pass it; see DESIGN.md.

`TMUX_ASK_ENTER_DELAY` (default `0.5`) sets the pause between pasting and pressing Enter. Raise it if a TUI drops the Enter.
`TMUX_CONNECT_HIGHLIGHT` (default `bg=colour24`) sets the picker tint.

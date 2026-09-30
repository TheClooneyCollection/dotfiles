# tmux agents

Connect AI agents (Claude, Codex, anything) running in tmux panes so they can message each other. You watch every pane and approve permissions yourself.

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

## Commands

| Command | What it does |
| --- | --- |
| `tmux-connect [target] [--as NAME] [--all]` | Name this pane and link it to `target` (name, `%id`, or `1.0`). No target opens a picker of panes in this window (`--all`: every window); the pane under the cursor is tinted. Unnamed panes get asked for a name. |
| `tmux-disconnect [name]` | Unlink from `name`, or from everyone. |
| `tmux-peers` | Show this pane's name and its connections. |
| `tmux-ask <name> [--reply] [msg]` | Paste a message into a connected pane and submit it. Reads stdin if no `msg`. |
| `tmux-peek <name> [lines]` | Print the last lines (default 40) of a connected pane. |

## How messages flow

```
claude:  tmux-ask codex "review src/auth"      → pasted into codex's pane
codex:   ...works, you approve its prompts...
codex:   tmux-ask --reply claude <<'MSG' ...   → pasted into claude's pane
```

- Requests say who sent them and how to reply. Replies say not to answer back, which stops loops.
- Nobody waits. The sender ends its turn, and the reply arrives later as a new prompt.
- If an agent is busy, Claude queues the pasted message. Typing in a pane while a message arrives will mix the two.

## Setup

- `~/.bin/tmux` on PATH (in `.config/fish/config.fish`).
- `prefix + A` popup binding and border-refresh hooks in `~/.tmux.conf`. Reload with `prefix + r`.
- Agents learn the protocol from the `tmux-agents` skill in `~/.claude/skills/` and `~/.codex/skills/` (`~/.codex-2nd/skills/` symlinks to the Codex one).
- **Codex:** its sandbox blocks the tmux socket. `~/.codex/rules/tmux-agents.rules` allows `tmux-ask`, `tmux-peers` and `tmux-peek` to run outside it without prompting (`codex-2nd` symlinks the same file).
- **Claude:** `tmux-ask`, `tmux-peers` and `tmux-peek` are allowlisted in `~/.claude/settings.json`. `tmux-connect` and `tmux-disconnect` stay yours and still prompt.

## How it works

State lives on the panes as tmux user options, with no files:

- `@agent`: the pane's name, unique across the tmux server.
- `@peers`: pane ids it links to.

Pane ids survive moving panes between windows. Closing a pane drops its links.
Inspect with `tmux show -p @agent` / `tmux show -p @peers`.

`TMUX_ASK_ENTER_DELAY` (default `0.5`) sets the pause between pasting and pressing Enter. Raise it if a TUI drops the Enter.
`TMUX_CONNECT_HIGHLIGHT` (default `bg=colour24`) sets the picker tint.

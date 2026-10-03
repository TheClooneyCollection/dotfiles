# tmux-agents: design notes

How the `tmux-*` scripts work, why they work that way, and the traps found while building them. For usage, see [README.md](README.md) and [docs/guide.md](docs/guide.md).

## Goals

- Agents (Claude, Codex, anything) in ordinary tmux panes can message each other.
- The user watches every pane and makes every permission decision in the agent's own UI.
- Any number of panes, connected ad hoc. There is no fixed layout or session launcher.
- No daemon and no state files.
- Sub agents are real agents in their own panes, hidden by default but one keystroke away, so their full history stays readable.

## Architecture

All state lives in tmux user options on the panes themselves: a pane's name, its links to other panes, and, for sub agents, their parent and state. Closing a pane cleans up after it, and there is nothing else to keep in sync. Links are explicit and symmetric, so the user always knows who can reach whom.

A message is text pasted into the receiver's pane and submitted, exactly as if the user had typed it. The sender ends its turn; the answer arrives later as a new prompt in its own pane. Every message carries the sender's and receiver's names and its own reply instructions, so an agent that never loaded the skill can still answer.

Sub agents are ordinary agents started by `tmux-spawn` in hidden windows of an `agents-<project>` session, linked to their parent. The `prefix + a` switcher lists and opens them, and a second status line (the chip) shows what each one is doing, fed by reports and hooks rather than screen scraping.

## Scripts

| File | Role |
| --- | --- |
| `lib.sh` | Shared helpers, sourced by the others: pane lookup, naming, peers, labels. Not executable, so it never shows up as a command even though `bin/` is on `PATH`. |
| `tmux-connect` | Picker, naming form, linking, popup mode, and agent mode (`--from`). |
| `tmux-disconnect` | Removes links. |
| `tmux-peers` | Lists connections. `--refresh` rebuilds labels (used by hooks). |
| `tmux-ask` | Sends a message, or queues it while the user is busy in that pane. |
| `tmux-peek` | Reads a peer's screen (`capture-pane -J`). |
| `tmux-spawn` | Starts a connected sub agent in a hidden window. `--run` is its in-window half. |
| `tmux-agent-report` | Sub agent progress, permission and turn-end reports for the chip. |
| `tmux-agents` | fzf switcher (`prefix + a`). `--list`, `--view`, `--chip` and `--alert` are among its helper modes. |
| `tmux-dismiss` | Kills an agent's pane. |

## Topics

- [State and protocol](docs/design/state-and-protocol.md): pane options, links, naming, connecting, message format and delivery, long messages.
- [Sub agents](docs/design/sub-agents.md): spawning, the switcher, done state and cleanup, closing, the status chip, alerts.
- [Environment](docs/design/environment.md): macOS bash 3.2, Codex's sandbox and shared daemon, permissions, install layout.
- [Pitfalls and testing](docs/design/pitfalls-and-testing.md): traps found while building, how to test without touching the user's server, known limitations.
- [Product decisions](docs/decisions/README.md): what the user decided about behaviour, and why, one per file.

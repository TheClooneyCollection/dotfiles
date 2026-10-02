# tmux-agents

English | [简体中文](README.zh-CN.md)

**Your sub agents shouldn't disappear when the task ends.** Built-in sub agents run out of sight. You get a summary at the end, and the work behind it is gone.

tmux-agents runs each Claude or Codex sub agent in its own tmux window instead. Watch its work in a live preview, or switch in to give direction.

Agents send tasks and updates to each other. Their panes stay until you close them, and their conversations remain afterward: in Codex you can find them in `codex resume`, in Claude in `claude --resume`.

See the work. Keep the history. Pick it up again.

- **Real sessions, not black boxes.** Every sub agent is a full Claude or Codex session with its whole history on screen. Approve a prompt, ask a follow-up, or correct it mid-task.
- **One glance to know who needs you.** A line above your status bar shows each sub agent working, done, waiting for permission or waiting for you.
- **Agents that talk to each other.** Tell Claude "connect codex and have it review this diff", and the reply comes back to Claude as a new message.
- **Stays out of your way.** Sub agents live in a hidden session per project. Nothing is added to your layout, and a message never lands while you're typing in that pane.
- **Just tmux and bash.** No server to run: the state lives on the tmux panes.

## Screenshots

<p align="center">
  <img src="docs/message-request.png" width="49%" alt="A request from Claude arriving in Codex's pane">
  <img src="docs/message-reply.png" width="49%" alt="Codex's reply arriving back in Claude's pane">
</p>

<p align="center">Claude asks Codex for a review, and the reply comes back as a new message.</p>

<p align="center">
  <img src="docs/agent-list.png" width="49%" alt="The agent list: sub agents with their status and parent, and a live preview of the selected one">
  <img src="docs/popup.png" width="49%" alt="A hidden Codex sub agent opened in a popup from the list">
</p>

<p align="center"><code>prefix + a</code> lists your sub agents with a live preview. Open one in a popup to answer it or give direction.</p>

Status bar: a line above your status bar keeps count, and turns red or amber when an agent needs you:

```
      ⠹ auth-review: reading src/auth.ts  │  api ⠹ 2 ✓ 1 · blog ⠹ 1
```

Design notes, protocol details and known pitfalls: [DESIGN.md](DESIGN.md).

## Install

The easy way: ask Claude Code or Codex to do it.

> Install tmux-agents for me by following https://github.com/TheClooneyCollection/tmux-agents/blob/main/skills/tmux-agents-setup/SKILL.md

It checks what you have, runs the installer, shows you each config change before making it, and then walks you through a quick start. Later, say "tmux-agents quick start" to any agent to take the tour again.

### By hand

Needs tmux 3.2+ and bash. `fzf` is optional (nicer pickers and the live agent list).

```sh
git clone https://github.com/TheClooneyCollection/tmux-agents.git
cd tmux-agents
./install.sh            # --dry-run to see what it does first
```

`install.sh`:

- links the `tmux-*` commands into `~/.local/bin` (`BIN_DIR` to change)
- links the `tmux-agents` and `tmux-agents-setup` skills into `~/.claude/skills/` and your Codex home
- copies the Codex rules (Codex skips symlinked `.rules` files)
- never overwrites a real file without `--force`

Then add these to your own config (`install.sh` prints them with your paths):

| | |
| --- | --- |
| **tmux** | `source-file ~/path/to/tmux-agents/tmux/tmux-agents.conf` in `~/.tmux.conf`, then reload |
| **PATH** | `~/.local/bin` |
| **Claude** | the `allow` rules from [`integrations/claude/settings.json`](integrations/claude/settings.json), into `~/.claude/settings.json` |
| **Codex** | the wrapper: [`integrations/fish/functions/`](integrations/fish/functions) or [`integrations/sh/codex.sh`](integrations/sh/codex.sh) |

<details>
<summary>What each one is for</summary>

- **tmux:** `prefix + a` (agents), `prefix + A` (connect), the sub agent chip, and hooks for border refresh, bell alerts and queued messages. If you linked the commands somewhere other than `~/.local/bin`, put `%hidden TMUX_AGENTS_BIN="/that/dir"` before the `source-file` line.
- **Claude:** agents can message, peek, spawn, report and close their own sub agents without prompting. `tmux-connect` (without `--from`), `tmux-disconnect` and plain `tmux-dismiss` stay yours and still prompt.
- **Codex:** Codex runs commands in a shared daemon whose `$TMUX_PANE` may be another pane, so the wrapper pins each Codex to its own pane (see DESIGN.md). Copy the fish functions into `~/.config/fish/functions/`, or `source` the sh file from `~/.bashrc` / `~/.zshrc`.
- **Optional:** tell your agents to use `tmux-spawn` for every sub agent, in `CLAUDE.md` / `AGENTS.md`. The skill explains how.

</details>

Update with `git pull`: the links pick up the new scripts. Re-run `./install.sh` if the rules changed.

Using more than one Codex account? See [the guide](docs/guide.md#more-than-one-codex-account).

## Quick start

1. Split a tmux window. Start `claude` in one pane and `codex` in the other.
2. Tell Claude: "use tmux-agents to connect to the codex pane and have it review this diff". The request lands in Codex's pane, and the reply comes back to Claude.
3. Tell Claude: "spawn a sub agent to add tests for the parser". It runs in a hidden window, and a line above your status bar shows how it's doing.
4. Press `prefix + a` to watch it. Enter opens it in a popup, `prefix + d` goes back.

Or let your agent show you: say "tmux-agents quick start".

## Keys

| Key | |
| --- | --- |
| `prefix + a` | The agent list, with a live preview |
| `prefix + A` | Connect this pane to another one |
| `prefix + d` | In a popup: back to the list. In the list: close it |

In the list: `enter` open · `ctrl-o` jump there · `ctrl-x` dismiss · `ctrl-d` close all finished · `ctrl-a` all panes / sub agents

Closed sub agents stay in a `closed` section at the bottom for 7 days: `enter` reopens one with its whole conversation. Or ask its parent to reopen it.

Status: `⠹` working · `✓` done · `⚠` waiting for permission (red) · `◆` needs you (amber) · `✗` exited

## Commands

Agents run these for you; each takes `--help`.

| Command | |
| --- | --- |
| `tmux-connect` | Name this pane and link it to another |
| `tmux-ask` | Send a message to a connected agent |
| `tmux-spawn` | Start a sub agent in a hidden window |
| `tmux-agents` | The agent list (`prefix + a`) |
| `tmux-peers`, `tmux-peek` | Show connections; read another pane |
| `tmux-dismiss`, `tmux-disconnect` | Close a sub agent; unlink panes |
| `tmux-agent-report` | Report progress for the status line |

How messages flow, sub agent details, settings and how it works: [the guide](docs/guide.md).

## License

MIT, see [LICENSE](LICENSE).

---
name: tmux-agents-setup
description: Install, update or configure tmux-agents for the user, then walk them through a quick start. Use when the user asks to install, set up, update or try tmux-agents, or asks for its quick start or a tour.
---

# Setting up tmux-agents

You are installing tmux-agents for the user and then showing them how to use it. Go step by step and keep the user in the loop:

- Before changing any file outside the tmux-agents checkout, show the exact change and wait for a yes. Back a file up before editing it.
- Never kill, restart or rename the user's tmux sessions. The only thing you may run against their tmux server is `tmux source-file`, after they agree.
- Don't install system packages yourself; tell the user the command.

If tmux-agents is already installed (`command -v tmux-spawn` finds it and `tmux list-keys | grep tmux-agents` shows the bindings), skip to the quick start, or to updating if the user asked for that.

## 1. Check

- `tmux -V` is 3.2 or newer, and `git` and `bash` exist. `fzf` is optional; without it the pickers and the agent list are plainer.
- The user's shell: `basename "$SHELL"` (fish, zsh, bash).
- Which agents they use: `command -v claude codex`.
- Whether you are inside tmux (`$TMUX` set). The quick start needs tmux.

## 2. Get the code

Clone into `~/.local/share/tmux-agents` unless the user wants another place:

```sh
git clone https://github.com/TheClooneyCollection/tmux-agents.git ~/.local/share/tmux-agents
```

If it is already there, update it with `git pull --ff-only` in that directory instead.

## 3. Run install.sh

Run `./install.sh --dry-run` from the checkout, summarize what it will link and copy, then run `./install.sh`.

- `skipped ...: exists and isn't a link` means the user has their own file there. Show it and ask before re-running with `--force`, which replaces it.
- If they use more than one Codex account, ask for the homes, and run it with `TMUX_AGENTS_CODEX_HOMES="name=$HOME/.codex-name ..."` so every account gets the skill and rules.

## 4. Configure

One item at a time; skip what is already in place.

1. **tmux.** Add `source-file <checkout>/tmux/tmux-agents.conf` to the user's tmux config (`~/.tmux.conf`, or `~/.config/tmux/tmux.conf` if that is the one they use). If the commands were linked somewhere other than `~/.local/bin`, put `%hidden TMUX_AGENTS_BIN="<that dir>"` on the line before. Then offer to reload it with `tmux source-file <config>`.
2. **PATH.** If `command -v tmux-ask` finds nothing, add `~/.local/bin`: `fish_add_path ~/.local/bin` for fish, or `export PATH="$HOME/.local/bin:$PATH"` in `~/.zshrc` / `~/.bashrc`.
3. **Claude** (if they use it). Merge the `permissions.allow` entries from `<checkout>/integrations/claude/settings.json` into `~/.claude/settings.json`: keep everything already there, add only the missing entries, and write valid JSON with a script (python3 or jq), not by hand.
4. **Codex** (if they use it). It must be started through the wrapper, which pins each Codex to its own tmux pane:
   - fish: copy `<checkout>/integrations/fish/functions/*.fish` into `~/.config/fish/functions/`. If they already have a `codex.fish`, show both and ask.
   - zsh/bash: add `source <checkout>/integrations/sh/codex.sh` to `~/.zshrc` / `~/.bashrc`.
5. **Optional.** Offer to add a line to `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md`: "Start sub agents with tmux-spawn (the tmux-agents skill), not the built-in sub agents."

## 5. Check it works

In a new shell: `command -v tmux-ask tmux-spawn` finds both, and in tmux `tmux list-keys | grep tmux-agents` shows `prefix + a` and `prefix + A`.

Tell the user that agents already running (you included) won't see the new PATH, wrapper, skill or permissions until they are restarted. Suggest restarting you inside tmux and saying "tmux-agents quick start" to continue.

## 6. Quick start

Walk the user through it one step at a time. Say what to do, then wait for them to do it before the next step. Keep explanations to a sentence or two.

1. **Two agents side by side.** In a tmux window, split it in two (`prefix + %`). Start `claude` on the left and `codex` on the right (through the wrapper, so plain `codex` in a new shell).
2. **Agents talking.** In Claude, say: "use tmux-agents to connect to the codex pane and have it review <a file in this project>". (Naming tmux-agents keeps Claude from reaching for some other Codex integration.) The request appears in Codex's pane, Codex works on it, and the reply comes back to Claude as a new message. Both panes now show `name ⇄ peer` on their top border.
3. **A sub agent.** Ask Claude: "spawn a sub agent to <a small task, like adding a test>". It runs in a hidden window, and a line above the status bar shows it working.
4. **Watch it.** Press `prefix + a`: the agent list with a live preview. Arrow keys move, Enter opens the agent in a popup where you can answer it or give direction, `prefix + d` goes back to the list, and `prefix + d` again closes it.
5. **Needs you.** If a sub agent waits for permission the line turns red; if it ends its turn without answering its parent, amber. Open it from the list to answer.
6. **Clean up.** The parent closes its sub agents when it is done with them. You can close one yourself with `ctrl-x` in the list, or every finished one with `ctrl-d`.

Finish by pointing them to the README for the full command list and more than one Codex account.

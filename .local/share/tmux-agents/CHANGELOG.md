# Changelog

## Unreleased

- **Reopen closed sub agents.** Each sub agent's session is recorded, so a closed one can come back with its whole conversation for 7 days: from a `closed` section at the bottom of the agent list (`enter`), or by asking its parent (`tmux-spawn --resume NAME`).
- **Agent list:** each agent takes two lines, with what it is doing underneath, grouped into a section per project.
- **tmux-ask:** a pane left in copy mode with no keys for 5 minutes is taken out of it so queued messages go through (`TMUX_ASK_COPY_IDLE_SECS`). Queued messages are kept per tmux server, and the delivery loop now gets the `TMUX_ASK_*` settings.
- **Fix:** Codex sub agents no longer show "needs you" while Codex names a new session; agents are told to ask the user in their reply, not with `--waiting`.

## v1.0.0 (2026-10-01)

First release, extracted from a dotfiles repo with its full history.

- **Connect panes.** `tmux-connect` names panes and links them; `prefix + A` connects from a picker. Agents can connect themselves ("connect codex and have it do xyz") with `tmux-connect --from`, which finds the other agent in the same window and names unnamed panes.
- **Messages.** `tmux-ask` pastes fenced requests and replies into a connected pane. Typing or scrolling in the receiver queues the message until you're done. Long messages are saved to a file.
- **Sub agents.** `tmux-spawn` starts Claude or Codex sub agents in hidden per-project sessions, in auto mode, connected to their parent, with a depth limit.
- **Agent list.** `prefix + a` opens `tmux-agents`: status, parent, project, current activity and a live preview. Open hidden agents in a popup, jump, dismiss, or clear finished ones.
- **Status chip.** An animated line above the status bar shows sub agents, with permission waits (red) and "needs you" (amber) taking focus.
- **Needs you detection** that knows when an agent is waiting on sub agents, sent requests, reported background work, or Claude background Bash commands.
- **Codex support.** Identity pinning wrappers for fish, bash and zsh, sandbox rules, and extra Codex accounts with `TMUX_AGENTS_CODEX_HOMES`.
- **Skills** for Claude and Codex, `install.sh`, and a setup skill so an agent can install tmux-agents and give you a quick start.

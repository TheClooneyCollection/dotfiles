# Changelog

## v1.6.1 (2026-10-03)

- The skills tell agents to reply as soon as a request's main work is done and send follow-ups (a deploy, a page going live) as notices.

## v1.6.0 (2026-10-03)

- **Idle agents.** Agents spawned without a task show grey `○ idle` in the list and chip until a request or progress report starts work.
- **Closed descendants in this window.** Closed agents follow their recorded ancestry through closed parents to a live ancestor, keeping the whole closed chain discoverable in its window.
- **Parent progress notices.** A sub agent sending its parent a progress notice stays working at turn end. A new request clears the wait, so unanswered work still shows as needs you.
- **Close agent subtrees.** Ancestors can dismiss any descendant and its whole subtree, deepest first, keeping each session available to resume. `--keep-children` leaves direct children unowned; `--done` skips subtrees with unfinished work.

## v1.5.0 (2026-10-03)

- **Window-scoped agent list.** `prefix + a` opens on this window and its descendants. `ctrl-t` switches to all windows; `ctrl-a` still switches between sub agents and every named pane. Returning from a hidden agent keeps the view and scope, and closed agents follow their recorded parent.
- **Pinned attention.** Sub agents needing permission or user input appear first from every window, longest wait first, with their owning window and project (the first visible ancestor for hidden agents). The chip stays global.
- **Tests:** `tests/list-scope.sh` covers membership, pinned order, closed records, empty windows and picker navigation.

## v1.4.0 (2026-10-03)

- **Visible sub agents.** `tmux-spawn --split <name-or-pane-id> [--right | --below] [--size N%]` opens a detached split, including with `--for`. Hidden windows remain the default. Only the new pane keeps its transcript on exit; reopening a closed split still uses a hidden window.
- **Tests:** `tests/spawn-split.sh` covers layout, ownership, environment, shared window settings, listing, messages, dismissal and hidden resume.

## v1.3.2 (2026-10-03)

- **Docs:** the agent chain's middle role is called "secondary" (was "coordinator") in the guide, skills and tests.

## v1.3.1 (2026-10-03)

- **Fix:** a sub agent that reports progress after replying to its parent stays done. The report set it back to working, so the turn end marked it needs you.

## v1.3.0 (2026-10-03)

- **`tmux-spawn --for <owner>`.** Spawn a sub agent for an agent you're connected to: it belongs to the owner, is connected only to it, starts without a task, and gets its first task from the owner, whom you brief. Depth counts from you, so main can spawn a worker for its coordinator that can still start sub agents. Tests: `tests/spawn-for.sh`.
- **Product decisions** are recorded one per file in `docs/decisions/`.
- **Fix:** a name that no longer exists (a closed agent's) is now an error. tmux's loose target matching sent a message for one to the agent in a window with a similar name. Only `%12`, `2`, `2.1`, `work:2` and `work:2.1` are taken as tmux targets.
- The skills tell agents to use the names `tmux-peers` shows now, not remembered ones.
- **Tests:** `tests/names.sh`.

## v1.2.1 (2026-10-03)

- **Fix:** a notice to a Claude sub agent waiting on background work (`--waiting`) no longer clears that and flags it as needs you.
- **Tests:** `tests/needs-you.sh` checks normal workflows don't flag sub agents as needs you, and real cases do.
- **Fix:** agents are told to inform sub agents with `tmux-ask --notice`, not a request. A request saying "no reply needed" put finished sub agents back to working, and they then showed as needs you.

## v1.2.0 (2026-10-03)

- **Connect across windows.** The `prefix + A` picker switches to every window with `ctrl-a` (remembered), shows each pane's project and what it's doing, and previews it. Agents can connect to another window's agent with `codex@<project>` or `claude@<window>`, or find it with `tmux-connect --list`. The agent on the other side gets a notice (`tmux-ask --notice`) saying who connected.

## v1.1.0 (2026-10-02)

- **Reopen closed sub agents.** Each sub agent's session is recorded, so a closed one can come back with its whole conversation for 7 days: from a `closed` section at the bottom of the agent list (`enter`), or by asking its parent (`tmux-spawn --resume NAME`).
- **Agent list:** each agent takes two lines, with what it is doing underneath, grouped into a section per project.
- **tmux-ask:** a pane left in copy mode with no keys for 5 minutes is taken out of it so queued messages go through (`TMUX_ASK_COPY_IDLE_SECS`). Queued messages are kept per tmux server, and the delivery loop now gets the `TMUX_ASK_*` settings.
- **Extra Codex accounts.** When `TMUX_AGENTS_CODEX_HOMES` is unset, `tmux-spawn` reads it from tmux's global environment so agents started earlier can spawn on extra accounts.

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

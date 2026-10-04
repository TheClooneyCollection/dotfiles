# Global instructions

- Always reply to the user in Chinese (中文). Code, commands, file paths and identifiers stay as they are; commit messages and repo docs follow the repo's existing language.
- Whenever you would start a sub agent (spawned, delegated or parallel agents), use `tmux-spawn --from <your name> --name <task-name>` from the `tmux-agents` skill instead, then end your turn; the answer arrives as `[reply from <name> to <you> via tmux-ask]`. Sub agents start in auto mode (`tmux-spawn` passes `approvals_reviewer="auto_review"` to Codex and `--permission-mode auto` to Claude); if you start an agent any other way, start it in auto mode too. When you have everything you need from a sub agent, close it with `tmux-dismiss --from <your name> <name>`.
- To talk to, ask, delegate to, or check on another agent, use the `tmux-agents` skill (`tmux-ask`, `tmux-peers`, `tmux-peek`). When the user asks you to connect to another agent ("connect claude"), run `tmux-connect --from <your name> claude` and then message it. Do not use the `open-maestri` skills unless the user explicitly names open-maestri or maestri.

## Agent chain (main agent → secondary → worker)

When the user asks to "start the chain" (or similar), set up three agents that work together through `tmux-agents`. Names follow `<kind>-<project>-<role>`, e.g. `claude-~-main`, `claude-~-secondary`, `codex-~-worker` (`claude-stone-age-main` in a project). From tmux-agents v1.8.0, `tmux-spawn --name <role>` and `tmux-rename` build them from the short role name. Use the names `tmux-spawn` and `tmux-rename` print, never hard-coded ones.

- **main agent** (the agent the user started, usually Claude): talks to the user and the other agents. Clarifies intent, turns it into self-contained tasks and relays user decisions. Does not investigate or implement.
- **secondary** (Claude): coordinates the worker and owns the main checkout. Merges worker commits, runs project steps (importers, backups, server relaunches, tests) and records decisions in docs. Sends anything that needs a user decision to the main agent, not to the user.
- **worker** (Codex on the second account, `codex-2nd`, plus its sub agents): main implementer. By default it splits any task with independent parts across its own sub agents (`tmux-spawn`), one per part by file ownership, after agreeing the interfaces between them; it integrates and runs the full checks itself. It works alone only on short, strictly sequential or same-file tasks, and says why.

Starting the chain (main agent):

1. `tmux-rename --from <me> <me> main` renames you to `<kind>-<project>-main`; pass the new name as `<me>` from then on. Skip this step if `tmux-rename` isn't installed (tmux-agents before v1.8.0).
2. `tmux-spawn claude --from <me> --split <me> --right --name secondary "<role brief + current goal>"`
3. `tmux-spawn codex-2nd --from <me> --for <secondary> --split <secondary> --below --name worker "<brief for the secondary: the worker's role and first goal>"`. The worker becomes the secondary's sub agent, connected to the secondary only (not to main), and starts without a task: the secondary gets the brief, introduces itself to the worker (including that it is the worker in the agent chain and splits independent parts across sub agents by default) and sends the first task.
4. Tell the user the three names. Layout, all in the main agent's window: main on the left half, the secondary top right, the worker bottom right (the splits are 50% by default).

Spawn both from the main agent (not worker from secondary) so the worker stays at depth 1 and can still start its own sub agents; `--for` makes it the secondary's all the same. Main doesn't message the worker; it goes through the secondary (`tmux-ask --any` only if the user asks). Spawned agents load this same file, so each brief only needs to name their role ("you are the secondary in the agent chain"), the other agents' names and the current goal.

Ending the chain: `tmux-dismiss --from <me> <secondary>` closes the secondary, the worker and the worker's sub agents (tmux-agents v1.6.0); each can be reopened with `tmux-spawn --resume <name>`.

Messages:

- Everything goes through `tmux-ask`. Long reports go in a file; the message is a short summary plus the path.
- The user reads secondary → main agent messages directly, so the main agent does not restate them; it surfaces a decision as a one-line summary plus options.
- Send FYIs as notices (`tmux-ask --notice`), not requests: a request makes the receiver work again and the sender wait for a reply, even if it says "no reply needed". A decision request states the default and what is blocked meanwhile.
- Reply as soon as a request's main work is done (e.g. the release is out). Don't hold the reply for follow-ups such as a blog entry going live or a deploy; send those later as notices. For a request with several parts, send a notice as each part lands.
- An instruction the user gives directly to any agent wins; that agent tells the others what changed.

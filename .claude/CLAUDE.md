# Global Claude Instructions

- Never use absolute paths in shell commands. Always use `.` or relative paths. The working directory is already set correctly.
- For git commands, always just run `git` directly. Never `cd` into the directory first, and never use `git -C <path>`. Just `git status`, `git commit`, etc.
- Never backslash-escape spaces in paths. Always quote paths that contain spaces (e.g. `"dir/with spaces/file"`).
- So instead of `find /Users/foo/Bar\ Baz -type f`, write `find . -type f`.
- Avoid em dashes. Rewrite the sentence, split it in two, or use a comma instead.

## Agent chain (main agent → secondary → worker)

When the user asks to "start the chain" (or similar), set up three agents that work together through `tmux-agents`. Names are whatever `tmux-spawn` assigns; use the names it prints, never hard-coded ones.

- **main agent** (the agent the user started, usually Claude): talks to the user and the other agents. Clarifies intent, turns it into self-contained tasks and relays user decisions. Does not investigate or implement.
- **secondary** (Claude): coordinates the worker and owns the main checkout. Merges worker commits, runs project steps (importers, backups, server relaunches, tests) and records decisions in docs. Sends anything that needs a user decision to the main agent, not to the user.
- **worker** (Codex on the second account, `codex-2nd`, plus its sub agents): main implementer. Sub agents split work by file ownership to avoid conflicts.

Starting the chain (main agent):

1. `tmux-spawn claude --from <me> --split <me> --right --name secondary "<role brief + current goal>"`
2. `tmux-spawn codex-2nd --from <me> --for <secondary> --split <secondary> --below --name worker "<brief for the secondary: the worker's role and first goal>"`. The worker becomes the secondary's sub agent, connected to the secondary only (not to main), and starts without a task: the secondary gets the brief, introduces itself to the worker and sends the first task.
3. Tell the user the two names. Layout, all in the main agent's window: main on the left half, the secondary top right, the worker bottom right (the splits are 50% by default).

Spawn both from the main agent (not worker from secondary) so the worker stays at depth 1 and can still start its own sub agents; `--for` makes it the secondary's all the same. Main doesn't message the worker; it goes through the secondary (`tmux-ask --any` only if the user asks). Spawned agents load this same file, so each brief only needs to name their role ("you are the secondary in the agent chain"), the other agents' names and the current goal.

Messages:

- Everything goes through `tmux-ask`. Long reports go in a file; the message is a short summary plus the path.
- The user reads secondary → main agent messages directly, so the main agent does not restate them; it surfaces a decision as a one-line summary plus options.
- Send FYIs as notices (`tmux-ask --notice`), not requests: a request makes the receiver work again and the sender wait for a reply, even if it says "no reply needed". A decision request states the default and what is blocked meanwhile.
- An instruction the user gives directly to any agent wins; that agent tells the others what changed.

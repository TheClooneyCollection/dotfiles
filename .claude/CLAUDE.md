# Global Claude Instructions

- Never use absolute paths in shell commands. Always use `.` or relative paths. The working directory is already set correctly.
- For git commands, always just run `git` directly. Never `cd` into the directory first, and never use `git -C <path>`. Just `git status`, `git commit`, etc.
- Never backslash-escape spaces in paths. Always quote paths that contain spaces (e.g. `"dir/with spaces/file"`).
- So instead of `find /Users/foo/Bar\ Baz -type f`, write `find . -type f`.
- Avoid em dashes. Rewrite the sentence, split it in two, or use a comma instead.

## Agent chain (main agent → secondary → worker)

When the user asks to "start the chain" (or similar), set up three agents that work together through `tmux-agents`. Names follow `<kind>-<project>-<role>`, e.g. `claude-~-main`, `claude-~-secondary`, `codex-~-worker` (`claude-stone-age-main` in a project). From tmux-agents v1.8.0, `tmux-spawn --name <role>` and `tmux-rename` build them from the short role name. Use the names `tmux-spawn` and `tmux-rename` print, never hard-coded ones.

- **main agent** (the agent the user started, usually Claude): the agent that receives "start the chain" is the main agent. Its first step is to name itself main (step 1: `tmux-rename` to `<kind>-<project>-main`), then it spawns the secondary and worker. It talks to the user and the other agents. Clarifies intent, turns it into self-contained tasks and relays user decisions. Does not investigate or implement.
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

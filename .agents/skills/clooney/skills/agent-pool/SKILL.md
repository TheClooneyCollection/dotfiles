---
name: agent-pool
description: Keep a pool of sub agents busy in parallel under one coordinator that hands out work and integrates it. Use when the user asks to keep N agents running, to spin up several agents on a body of work, or when a large backlog splits into independent parts.
---

One **coordinator** owns a **pool** of sub agents and a **queue** of tasks. The pool stays full until the queue runs dry. Commands for spawning, messaging and progress reports come from the `tmux-agents` skill; load it first.

## Roles

- **Coordinator**: plans the split, keeps the queue, hands out tasks, integrates results, runs the full checks and commits. It alone edits shared files (core modules, generated indexes, metadata, changelog, build config).
- **Pool member**: takes one task, edits only the files that task owns, runs that task's own tests, then reports back and asks for the next task. Members never commit.

## Start

1. List the work that can run in parallel. Each task names the files it owns, the interface it touches, its checks and what to report.
2. Agree interfaces first: anything two tasks both depend on is fixed (or done by the coordinator) before either starts.
3. Fill the queue with more ready tasks than the pool size, each self-contained enough for any member to pick up cold.
4. Spawn members up to the pool size. The default is 5 to 10; the user's number wins.

Depth limit: when the coordinator cannot spawn (it is already at the deepest level), it asks its own parent to spawn members with `--for <coordinator>`, so they still belong to the coordinator.

## Running

- **A finished member asks for more.** It replies with its result and asks the coordinator for the next task; the coordinator answers with one from the queue. Members stay live between tasks.
- **Refill only below the floor.** Spawn a replacement when the pool drops under its lower bound (a member closed, crashed, or was dismissed).
- **Ownership is exclusive.** A member that needs a change outside its files asks the coordinator, who makes it or reassigns the task. Same worktree is fine under this rule.
- **Integrate one result at a time.** The coordinator merges a member's change, runs the full checks, then commits. A failing check goes back to the member that wrote it, with the failure.
- **Keep the queue ahead.** Whenever a task is handed out, top the queue up from the backlog, splitting larger items so the next member always has work.
- Report the split and each landed batch to whoever the coordinator answers to, as notices.

## Stop

Wind down when the queue is empty, the user says stop, or the remaining work is strictly sequential. Dismiss idle members, keep the ones still finishing, and report what landed, what is left and why it could not be parallelized.

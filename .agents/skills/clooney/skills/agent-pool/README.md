# agent-pool

Keeps a pool of sub agents busy in parallel. One coordinator splits the work, hands out tasks, merges results and commits; the members each work on one task at a time.

**Why:** I had a pile of work that could run in parallel and wanted 5 to 10 agents on it at once, without them stepping on each other's toes. One coordinator hands out tasks from a queue and merges results, and each member owns its own files.

**Use it:** ask to keep N agents running, spin up several agents on a body of work, or hand over a backlog that splits into independent parts.

## How it works

- The coordinator lists tasks that can run in parallel, each with the files it owns and its checks, and fixes shared interfaces first.
- It spawns members up to the pool size (5 to 10 by default; your number wins).
- A member edits only its own files, runs its task's tests, reports back and asks for the next task. Members never commit.
- The coordinator merges one result at a time, runs the full checks and commits. Failures go back to the member that wrote the change.
- It winds down when the queue is empty, you say stop, or the rest is strictly sequential, and reports what landed and what is left.

## Needs

[tmux-agents](https://github.com/TheClooneyCollection/tmux-agents) for spawning and messaging the members.

Agent instructions: [SKILL.md](SKILL.md).

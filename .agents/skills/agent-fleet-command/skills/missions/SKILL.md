---
name: missions
description: Track chain missions and answer Agent Fleet Command instructions. Use when a chain starts a mission, a secondary begins a turn or receives a fleet-command instruction, or a worker reports progress or hands work back.
---

# Missions

Use `fleet-command` with your own agent name: set `FLEET_AGENT` or pass `--from NAME` before the subcommand. With tmux-agents, use your own recorded name; do not borrow another role's identity.

- **Main:** create the mission with `fleet-command mission add "TITLE"` and retain its printed ID. Send direction to the chain's secondary with `fleet-command send SECONDARY "TEXT" --mission ID`; include the mission ID when delegating work.
- **Secondary:** start each turn with `fleet-command inbox`. Update status and ownership with `fleet-command mission set ID --status STATUS --owner NAME`. Status is `open`, `doing`, `blocked`, `done` or `dropped`; record plan approval with `fleet-command log MISSION_ID "TEXT" --kind decision`. Answer each instruction with `fleet-command reply INSTRUCTION_ID "ANSWER"`; use this reply command instead of replying through tmux-ask so the instruction leaves the inbox.
- **Worker:** append progress, handoff and completion with `fleet-command log MISSION_ID "TEXT" --kind progress|handoff|done`, choosing one kind. The secondary owns mission status changes; a worker's `done` log does not mark the mission done.

Successful writes print only what callers need: `mission add` prints the mission ID and `send` the instruction ID, each on its own line; `log`, `mission set` and `reply` are silent. Add `--verbose` to any of these commands for the full JSON response (including send delivery details). Errors stay on stderr with a nonzero exit status.

When the server cannot knock, the instruction still waits in the inbox; checking at the start of each turn finds it. `queued` means the reminder will arrive later; do not resend it. If the server is unavailable, the command fails quickly: skip that update and continue the assigned work.

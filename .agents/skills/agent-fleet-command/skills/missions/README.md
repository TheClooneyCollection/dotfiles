# Missions

Keep a chain's missions, progress and instruction replies in Agent Fleet Command.

**Why:** I run a fleet of agent chains, one per project, and have to visit each project's main agent to see what it is doing; this skill records the work in one shared command center.

Use it when starting a mission, checking a secondary's inbox, or reporting worker progress. It needs the installed `fleet-command` CLI, a running local server and the caller's agent name in `FLEET_AGENT` or `--from`. Server outages do not block the chain's work.

Files: [SKILL.md](SKILL.md) defines the role workflow. The [project README](../../README.md) covers installation and command examples.

Write commands keep output minimal; use `--verbose` for full JSON. See the [CLI output contract](../../docs/technical/cli.md).

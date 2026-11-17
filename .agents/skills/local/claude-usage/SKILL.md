---
name: claude-usage
description: Measure where Claude Code tokens go, per project, day, model, agent or chain role from local transcripts, and the fixed context a fresh session starts with. Use when the user asks who or what used the most Claude tokens, why usage or cache read is high, or how big a new session's context is.
---

## Who used the tokens

Run `.bin/claude-usage` from `~`; `--help` lists the flags (`--by`, `--days`, `--today`, `--since`, `--limit`). It scans every transcript, so allow a few minutes of timeout.
- For a 5-hour limit window, use `--since HH:MM` (local time today) or `--since YYYY-MM-DDTHH:MM`. To find when heavy use started, rerun with a few earlier `--since` times and compare totals.

- Rows are wide. Read them with `awk '{print $1, $(NF-2), $(NF-1), $NF}' | column -t` (name, total, requests, avg context).
- Agent names come from the first tmux-ask message a session received; `(unnamed)` is a session nobody messaged. For chain roles, group `--by agent` names on their `-main` / `-secondary` suffix; the rest are sub agents.
- Codex workers are not in these numbers.
- Cache read ≈ avg context × requests. High avg context means long sessions; high requests means many tool calls, messages or polling. Name which one drives the top rows.

## Fixed overhead of a new session

- Headless: `claude -p "reply with just ok" --output-format json --max-turns 1` and sum `input_tokens + cache_read_input_tokens + cache_creation_input_tokens`. Test a cut before making it with `--disallowedTools X` or `--settings '{...}'` and diff against the baseline.
- Headless misses Artifact, AskUserQuestion and SendFeedback and undercounts skills. For those, ask the user to run `/context` in a fresh session; trust its total, not the System tools row. Its percentage is of `autoCompactWindow` (250k in settings); the status line divides by the model's own window, so it reads lower. Check the window size the status line shows before treating the gap as a bug.
- Knobs in `.claude/settings.json`: `permissions.deny` (whole tool names), `skillOverrides` (`off` / `user-invocable-only` / `name-only`), `env.ENABLE_CLAUDEAI_MCP_SERVERS`. Check what is already there before adding.
- Measure before recommending a cut; early guesses here were wrong both ways.

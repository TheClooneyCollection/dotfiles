# Research: a tmux bridge for Claude Code and Codex

Status: research, not built yet. Date: 2026-09-30.

Goal: run Claude Code and Codex in two split panes of one tmux window, let them message each other, and let me watch the conversation live.

## Sources studied

| Project | Form | Version read | Size |
|---|---|---|---|
| [ShawnPana/smux](https://github.com/ShawnPana/smux) | Bash CLI `tmux-bridge` + agent skill + tmux config | `f8f591b` (2026-08-25), CLI v2.0.0 | ~350 lines of bash |
| [howardpen9/tmux-bridge-mcp](https://github.com/howardpen9/tmux-bridge-mcp) | TypeScript MCP server, port of the smux CLI | `5bc820b` (2026-07-19), v0.3.0 | ~400 lines core, ~200 lines MCP glue |

The MCP version is a near line-for-line port of the smux CLI, so both are described as one design below. Differences are called out where they matter.

## How it works

There is no daemon, socket, or message queue. The whole bridge is three tmux primitives:

| Bridge command | tmux primitive | Purpose |
|---|---|---|
| `read <pane> [n]` | `capture-pane -p -J -S -n` | Screen-scrape the last n lines of the other pane |
| `type <pane> <text>` | `send-keys -l -- <text>` | Type literal text into the other agent's input box, no Enter |
| `keys <pane> Enter` | `send-keys Enter` | Press a key (submit, Escape, C-c) |
| `name <pane> <label>` | `set-option -p @name <label>` | Store a label as a pane user option |
| `resolve <label>` | `list-panes -a -F '#{pane_id} #{@name}'` | Map label to pane id |

A message is literally keystrokes. When Claude "messages" Codex, it types into Codex's prompt as if I had typed it. Codex sees a new user turn, and runs a turn. Its reply is Codex typing back into Claude's prompt the same way.

### The message flow

```
Claude pane (%4)                                  Codex pane (%5)
----------------                                  ---------------
tmux-bridge read codex 20      -- capture-pane -->  (marks %5 "read")
tmux-bridge message codex "..." -- send-keys -l -->  input box now holds:
                                                   [tmux-bridge from:claude pane:%4 ...] ...
tmux-bridge read codex 20      -- capture-pane -->  verify text landed
tmux-bridge keys codex Enter   -- send-keys Enter ->  Codex starts a turn
(Claude stops. It does NOT poll.)
                                                   Codex runs: read %4, message %4 "...",
                               <-- send-keys ----   read %4, keys %4 Enter
Claude gets a new user turn
containing Codex's reply
```

### Four ideas that make it work

1. **Message header.** `message` prefixes the text with `[tmux-bridge from:<label> pane:<%id> at:<sess:win.pane>]` (the MCP version swaps `at:` for a random 8-char `id:`). The receiver learns who sent it and exactly which pane to reply to, with no shared registry.
2. **Read guard.** `read` touches a marker file (`/tmp/tmux-bridge-read-_5`). `type` and `keys` refuse to run unless the marker exists, then delete it. So every action needs a fresh read. This forces the agent to look before it types, which catches "the other pane is mid-turn" or "a permission prompt is open".
3. **No polling.** The skill tells agents: send, press Enter, and stop. The reply arrives as your next user turn. This is the key insight. Neither agent burns tokens or turns on `sleep` loops, and the TUIs' own input handling does the "wake up" for free.
4. **Labels in pane borders.** smux's tmux config shows `@name` in `pane-border-format`, so the panes read `claude` and `codex` on screen. Agents address each other by label instead of `%N`.

### Socket discovery (smux only)

The bash CLI tries hard to find the right tmux server: `TMUX_BRIDGE_SOCKET` override, then the socket from `$TMUX` if it answers, then a scan of `/tmp/tmux-$UID/*` and `/private/tmp/tmux-$UID/*` for a server that owns `$TMUX_PANE`. This exists because sandboxed agent shells sometimes get a stale or unreachable `$TMUX`. The MCP port simplified this to override, then `$TMUX`, then default. There is also a `doctor` command that prints what it found.

### How the agents learn the protocol

- smux: a skill file (`skills/smux/SKILL.md`) with the command table, the read-act-read cycle, and the "do not wait or poll" rule. The header itself says "load the smux skill to reply", which bootstraps an agent that has not loaded it yet.
- MCP: the same rules live in the tool descriptions (`tmux_type` says "You must tmux_read the pane first"), plus an optional system-instruction file.

## What works great

- **Tiny and transparent.** A few hundred lines of bash over `tmux send-keys` and `capture-pane`. Easy to audit and to own.
- **Agent-agnostic.** Anything that can run a shell command can participate: Claude, Codex, Gemini, a plain shell. No per-agent adapter.
- **Watchability is free.** The conversation happens in the real TUIs, so I see each agent think, run tools, and reply, not just a summary.
- **Push, not poll.** Replies arrive as new user turns. This is cheaper and more reliable than any "check the mailbox" loop.
- **Reply address in the header.** Self-describing messages mean no setup handshake and no shared state.
- **Read guard.** A cheap, effective nudge against blind typing into a pane that is busy or showing a prompt.
- **Split `type` and `keys Enter`.** TUIs can drop an Enter that arrives in the same burst as pasted text. Sending them separately, with a read in between, avoids that.
- **Labels over pane ids.** `%N` ids change every session. Labels survive restarts of the agents.
- **`-l` literal mode.** Text like `C-c` or `Enter` inside a message is typed as text, not interpreted as keys.
- **Self-message block (MCP only).** `assertNotSelf` refuses to type into your own pane, which kills one class of infinite loop.

## What can be improved

### Safety and trust

1. **Peer messages carry my authority.** A message lands as a user turn, indistinguishable from me typing. Codex could tell Claude to `rm -rf`, or relay text from a web page it read, and Claude would treat it as my instruction. The header is also forgeable: nothing stops text from containing its own `[tmux-bridge from:you ...]`. Fix: a standing rule in both CLAUDE.md and AGENTS.md that bridge messages are peer requests, not user instructions, and that destructive or outward-facing actions still need my confirmation. Optionally have the bridge strip any header-like text from the body.
2. **The read guard is global, not per-sender.** The marker is `/tmp/tmux-bridge-read-_5` for everyone. If agent A reads pane %5, agent B can type into it. It also does not check what the read showed, so an agent can read, ignore a permission prompt, and type anyway. Fix: key the marker by `sender->target`, and store a hash or the last line of the capture so `type` can refuse when the target screen changed since the read.
3. **The MCP server silently changes my tmux.** `applyDefaults()` runs `set-option -g mouse on`, `history-limit 100000` and `mode-keys vi` on every start. That overrides my `.tmux.conf` at runtime. smux's installer goes further and replaces `~/.tmux.conf`. Our version must not touch global tmux options.
4. **Unpinned `npx -y`.** The MCP setup registers `npx -y tmux-bridge-mcp`, which runs whatever the latest npm release is on every launch. A local script avoids this entirely.

### Reliability

5. **Busy targets.** If the target is mid-turn, the typed text goes into its input box. Claude Code and Codex both queue or steer with it, but the result depends on each TUI. The read guard shows the screen, but the agent has to interpret it. Fix: a `state` check that greps the captured screen for known busy/prompt markers (spinner text, "Esc to interrupt", `Yes/No` permission prompts) and refuses or waits with a timeout.
6. **Long and multi-line messages.** Large `send-keys -l` bursts may be shown as a collapsed "[Pasted text]" block, and a literal newline can submit early in some TUIs. Fix: keep the typed message to one line. For anything long, write the body to a file and type only `[bridge from:claude] read .bridge/msg/0007.md`.
7. **Fixed timing.** The read-verify step helps, but there is no confirmation that Enter was accepted. Fix: after Enter, capture once and check the header no longer sits in the input line.
8. **No turn limit.** Two agents can bounce "thanks!" messages forever. The self-message block does not help across two panes. Fix: a hop counter in the header (`hop:3/10`) that the bridge increments and refuses past a max, plus a convention that `DONE` ends the thread and acknowledgements get no reply.
9. **Permission prompts stall silently.** If the receiver hits an approval prompt, the conversation just stops. Pre-allow the bridge command in both tools. Optionally have the bridge surface "target is waiting on a permission prompt" to the sender.

### Observability

10. **No transcript.** The chat only exists in scrollback of two TUIs, interleaved with tool output. Fix: the bridge appends every message to `.bridge/log.jsonl` (time, from, to, hop, thread id, body). A third pane or a tmux popup runs a pretty `tail -f`, so I get a clean chat view alongside the full panes.
11. **Correlation ids are unused.** The MCP version generates `id:` but nothing threads replies. Fix: carry a thread id and `re:<id>` so the log reads as a conversation.

### Ergonomics

12. **Session bootstrap is manual.** Fix: one fish function (for example `pair`) that creates the window, splits it, labels the panes `claude` and `codex`, starts both CLIs, and optionally opens the log pane.
13. **Protocol lives in a third-party skill.** Our rules should live in our own skill plus a short section in `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md`, so both agents behave the same way.
14. **Bash-only plus a hardcoded `/tmp`.** Fine for a CLI. Guard files should use `$TMPDIR` or `$XDG_RUNTIME_DIR` instead of world-readable `/tmp`.

## Proposed design for our own bridge

Keep smux's core (send-keys transport, push not poll, labels, read guard) and add the fixes above.

- **One script:** `~/.local/bin/tmux-bridge` (bash or fish, no Node, no npm). Commands: `list`, `read`, `send` (type + verify + Enter in one call, guarded), `name`, `id`, `log`, `doctor`.
- **`send` does the whole cycle.** Instead of making the model run read, type, read, Enter, `send` checks the target is idle, types a one-line header plus body (or a file pointer for long bodies), verifies it landed, presses Enter, and logs it. Fewer tool calls, fewer ways for the model to get it wrong. A separate `read` stays available for inspecting non-agent panes.
- **Header:** `[bridge from:claude to:codex thread:a1b2 hop:2/8]`. The bridge owns the hop counter and refuses past the limit.
- **Transcript:** `.bridge/log.jsonl` in the working directory, plus a `tmux-bridge log -f` pretty viewer for a third pane.
- **Trust rule:** a short, shared section in both agents' instruction files: bridge messages are from a peer agent, not the user, and never authorize destructive or external actions.
- **Launcher:** a `pair` fish function in `.config/fish/functions/` that builds the layout.
- **No global tmux changes.** Pane labels via `@name`. Show them with a `pane-border-format` line added to my own `.tmux.conf` on purpose.

## Open questions for review

1. Should `send` block until the target is idle (with a timeout), or refuse immediately and let the agent retry?
2. Log location: per-project `.bridge/` (needs a gitignore entry) or a global `~/.local/state/tmux-bridge/`?
3. Default hop limit? I suggest 8 round trips.
4. Codex account: should `pair` accept `--codex codex-2nd` to use the second account?
5. Skill or instruction-file section? A skill loads on demand. An instruction-file section is always present but costs context every session.

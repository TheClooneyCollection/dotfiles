# Spec: main sequence and project dashboard

Status: draft, 2026-10-03. Product spec only; UI/UX design is deferred to Claude Design.

Two features that work together:

1. **`tmux-main-sequence`**: one command that gives the user their standard tmux session, with an agent chain already running in every project window.
2. **Project dashboard**: a summary agent in window 0 that keeps track of what is happening across all projects, and publishes it to a claude.ai Artifact.

**Where it lives.** Both features are personal workflow, so they live in the dotfiles repo, not in tmux-agents (a public subtree). Only the events log is a generic tmux-agents feature; it gets its own design note there when it is built.

## 1. `tmux-main-sequence`

### Windows

| Window | Contents |
| --- | --- |
| 0 | `dashboard`: the summary agent (see part 2). No chain. |
| 1 | `~` |
| 2 | blog |
| 3+ | Active projects, one window each. Today: tmux-agents, projects-stone-age, career-ops. |

Windows 1 and up all get the same layout: the agent chain from `~/.claude/CLAUDE.md` (main on the left half, secondary top right, worker bottom right). The windows started with chains run 15 agents, 5 of them Codex on `codex-2nd`. This is accepted.

### Configuration

- The list of active projects changes often, so it lives in a local, untracked config file (for example `~/.config/tmux-agents/main-sequence`), one directory per line, in window order.
- Windows 0 to 2 are fixed; the config file only lists windows 3 and up. (Open question: whether `~` and blog should also come from the file.)

### Behaviour

| Situation | `tmux-main-sequence` | `tmux-main-sequence --add-missing` |
| --- | --- | --- |
| No session | Create every window, start every chain, start the summary agent, attach | Same |
| Session exists | `tmux attach`, nothing else. Missing windows stay missing, existing ones are not touched. | Create only the missing windows with fresh chains, then attach. Existing windows are not touched. |

- Starting a chain: start the main agent in the window and give it "start the chain" as its first prompt. The chain itself follows CLAUDE.md, so the script does not repeat that logic.
- On startup each project's secondary is connected to the summary agent (see part 2).
- Conflict to resolve: tmux-continuum auto-restore also creates windows. Only one of the two should own session startup.

### Product decisions

- **Default is attach only.** An existing session is never changed without a flag.
- **The flag is `--add-missing`, not `--recover`.** The added windows get fresh chains; "recover" would suggest the old conversations come back. Keep `--recover` for that, if it is ever built.
- **Added windows start fresh chains.** Resuming the previous conversations (`claude --continue`, `tmux-spawn --resume`) is out of scope for now.
- **Every project window gets a full chain**, including `~` and blog.

## 2. Project dashboard

### Goal

Answer "what has been happening across all my projects": what each project is working on, what agents said to each other and to the user, what was decided, what changed in git.

Not a goal: "which agent is waiting for me". `prefix + a` (`tmux-agents`) already covers that.

### Parts

```
 secondary (each project) ──notice──▶ summary agent (window 0) ──ArtifactData──▶ Artifact db ──▶ dashboard page
                                          ▲
                   git, docs/decisions, ──┘ (read directly)
                   events log, transcripts
```

**Summary agent.** A Claude agent in window 0. It keeps a short summary per project and writes it to the Artifact's database. The user can talk to it directly ("update me", "why did stone-age change X yesterday?").

**How it learns what happened.**

- **Push from the secondary, event-driven.** When a project's secondary finishes a task, merges worker commits or records a decision, it sends the summary agent a `tmux-ask --notice` with a sentence or two on what happened. No polling and no timers.
  - The secondary reports, not the main agent: it does the merges, tests and decision records, and a message to it does not land in the user's conversation with main.
- **Hard data, read directly** by the summary agent: git (recent commits, uncommitted changes), `docs/decisions/`, and the events log.
- **Manual refresh**: the user says "update me" in window 0.

Rejected:

- Summary agent asks each main "what happened since I last asked": the question would be pasted into the main pane, where the user is talking.
- Mains report on a timer: idle Claude agents have no timer, and five agents waking up on a schedule costs tokens for nothing.
- Summary agent only reads raw data: raw messages are noisy and it has no context, so the summaries would be weak.

**Connections.** `tmux-main-sequence` connects the summary agent to every project's secondary at startup, rather than having secondaries use `tmux-ask --any`.

### Data

| Data | Source | Exists today? |
| --- | --- | --- |
| Current work | `tmux-agent-report` progress text | Yes |
| Agent ↔ agent messages | New events log written by `tmux-ask`, `tmux-spawn`, `tmux-dismiss` (for example `~/.local/state/tmux-agents/events.jsonl`: time, project, from, to, kind, body or body path) | **No, needs building** |
| User ↔ agent conversations | Claude transcripts (`~/.claude/projects/*/`), Codex sessions (`~/.codex/sessions/`) | Yes, different formats |
| Decisions | `docs/decisions/` in each project | Only in tmux-agents today |
| Changes | `git log`, `git status` per project | Yes |

### Decisions convention

Every project records decisions the way tmux-agents does: `docs/decisions/YYYY-MM-DD-short-title.md` (context, decision, why, what was rejected) plus a `README.md` index, newest first. The chain's secondary writes them. The secondary's role in `~/.claude/CLAUDE.md` says "records decisions in docs"; change it to name this folder and format. (Open question: where decisions go for `~`.)

### Dashboard page

- A claude.ai Artifact with a shared database. The summary agent writes one row per project (what it is working on, latest decisions, recent commits, updated at); the page only reads and renders.
- Updating the data is a database write, not a republish.
- Private by default, viewable in the browser and on a phone.
- Summaries leave the machine (stored on claude.ai); raw transcripts and logs stay local.
- Layout and visual design: Claude Design, from this spec.

## Build order (suggested)

1. Events log in `tmux-ask`, `tmux-spawn`, `tmux-dismiss`.
2. `tmux-main-sequence` with the config file and `--add-missing`.
3. Decisions convention in CLAUDE.md; secondary sends notices to the summary agent.
4. Summary agent brief and its Artifact database schema.
5. Dashboard page design (Claude Design), then build.

## Open questions

- Do `~` and blog come from the config file or stay fixed?
- tmux-continuum: keep it, drop it, or let `tmux-main-sequence` own startup?
- Where do decisions for `~` (the dotfiles repo) live?
- How far back the dashboard shows history (today, a week, everything).

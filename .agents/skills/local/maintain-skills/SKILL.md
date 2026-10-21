---
name: maintain-skills
description: Inspect, compare, import, update or clean up skills managed by these dotfiles across configured upstream sources and agent clients. Use for skill collection maintenance, adding an upstream source, or changing which agents have a skill installed.
---

Run `.bin/skill-manager` from the dotfiles root. Configuration, import records and per-agent installation inventory live in `.config/skill-manager/`. Consult `README.md` there for configuration fields and command examples. Upstream files retain their repository layout under their source directory; local skills remain editable in place.

## Inspect and review

- `sources` lists configured sources. `list --source NAME` discovers upstream skills without installing them. `installed` reads registration records offline; `--source` and `--agents` filter them. Verify actual links before cleanup: this is an intended installation inventory, not a live filesystem report.
- `check` (the default action) checks all imported sources and the registered client links. Use `--source NAME` to compare one source. Exit codes are 0 unchanged, 1 differences, 2 failure.
- `diff --source NAME [PATH ...] --ref COMMIT` compares local content with a pinned GitHub revision. Explain behavior changes, supporting files, invocation metadata, executable-bit changes, dependencies and any local edits. Metadata changes are reported separately; inspect the corresponding upstream documents at that revision.

Checking authorizes inspection only. Apply imports, updates or client removals when the user requests them; existing explicit authorization is sufficient. Pin the reviewed GitHub commit with `--ref` when applying reviewed changes.

## Import and maintain

`import --source NAME PATH` imports a complete skill directory and installs it to all default agents: Claude, Codex and codex-2nd. `--agents claude,codex` chooses a subset for that import. `update --source NAME [PATH ...]` preserves each skill's recorded agent choices and rejects `--agents`; it does not reactivate uninstalled clients. Upstream deletions, local modifications and link conflicts require review before proceeding. Keep upstream content unchanged and local adaptations in the local source.

Use `install --source NAME PATH --agents AGENT` to add a client link for an already imported skill. Missing registered links are repaired during mutations. Local sources use the same import/install/uninstall workflow, but their files are not copied or overwritten; local edits are legitimate and check only verifies discovery and links.

For a new source, add a configuration entry with its repository, directory, skill roots and required attribution files. GitHub source directories must be distinct from local source directories. For a local source, configure a root containing skill directories. Inspect dependencies outside selected skills and explain any additional selection needed; imports do not resolve dependencies automatically.

Explicitly allow each new source directory and new client symlink in `.gitignore`; unrelated skills remain excluded. Inspect `git status --short --untracked-files=all` and `git diff --check`, run `python3 .bin/tests/test-skill-manager.py`, and verify inventory entries resolve to the expected source. The script preserves upstream invocation metadata; allow discovery to refresh after installing new skills.

## Cleanup

`uninstall --source NAME PATH --agents AGENT` removes that client's registration and matching symlink while retaining the shared source. Without `--agents`, install/uninstall targets all configured default agents. A replaced link or a real directory at that path causes a conflict rather than deletion. Skills with no remaining clients stay imported so they can be inspected or reinstalled. Removing shared source files or dropping an entire source is a separate explicit task.

The script never schedules work, commits or pushes. Report the selected source, revision, clients, remaining differences and verification. Commit/push only when requested. The old `.bin/mattpocock-skills` command forwards to this manager with `--source mattpocock`.

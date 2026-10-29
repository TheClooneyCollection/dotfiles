# Skill manager

`.bin/skill-manager` vendors selected GitHub skills and registers per-agent
symlinks. `.bin/mattpocock-skills` is a compatibility wrapper supplying
`--source mattpocock`.

GitHub API calls authenticate with `GH_TOKEN`, `GITHUB_TOKEN` or `gh auth token`
when available; anonymous calls hit the 60/hour rate limit quickly.

- `config.json`: named sources, client directories and default clients.
- `lock.json`: per-source imported paths, pinned commits, file hashes/executable
  bits and each skill's chosen agents. This is the installation policy.
- `installations.json`: generated per-agent link/source inventory for inspection
  and cleanup. Paths are relative to the dotfiles root.

First imports default to **claude, codex, codex-2nd**. `--agents` accepts a
comma-separated subset. Updates preserve existing selections, including an empty
selection after uninstalling all clients. Source files remain available after
uninstall; registered missing links are repaired by mutations.

```sh
.bin/skill-manager sources
.bin/skill-manager list --source mattpocock --category productivity
.bin/skill-manager installed --agents claude
.bin/skill-manager check                         # all imported sources, read-only
.bin/skill-manager diff --source mattpocock --ref COMMIT
.bin/skill-manager import --source mattpocock skills/engineering/tdd --agents claude --ref COMMIT
.bin/skill-manager update --source mattpocock --ref COMMIT
.bin/skill-manager install --source mattpocock skills/engineering/tdd --agents codex,codex-2nd
.bin/skill-manager uninstall --source mattpocock skills/engineering/tdd --agents claude
.bin/skill-manager import --source local my-skill  # all three default agents
```

`import` accepts explicit upstream paths, or `--category` for an entirely new
category. For an already partially imported category, import new paths explicitly.
`install` and `uninstall` operate on already imported paths and do not fetch
upstream; omitting `--agents` targets all default clients. `installed` is offline
and displays registrations, not live filesystem status. `check` verifies links
against those registrations. `--agents` is rejected on update to avoid silently
changing the installation policy.

## Adding a source

Add an entry to `config.json`'s `sources`, then use `list --source NAME`:

```json
{
  "kind": "github",
  "repository": "OWNER/REPOSITORY",
  "ref": "main",
  "directory": ".agents/skills/OWNER",
  "skill_roots": ["skills"],
  "required_files": ["LICENSE"],
  "parent_readme": true
}
```

`skill_roots` are search roots relative to the repository; use `"."` for skills
at the repository root, or another directory for other layouts. `--category`
filters the first directory below those roots. `required_files` lists exact
attribution/document paths to retain; choose them for the repository's actual
license layout. `parent_readme` additionally retains each imported skill's
parent README when present. Each source needs its own non-overlapping directory.
GitHub fetching currently uses the public API and codeload; other Git hosts and
private-repository authentication are not implemented.

A local source uses `"kind": "local"`, `directory`, and `skill_roots`. Its
files stay editable in place; import registers their links, update preserves the
files and selected agents. The bundled local source is `.agents/skills/local`.
Skill references/dependencies outside the selected directory are not resolved
automatically. Configure clients as name-to-directory mappings; `default_agents`
sets the import/install/uninstall defaults.

Allow each new source directory and client link explicitly in `.gitignore`.
This tool intentionally leaves Git tracking choices to the user/maintenance skill.
Source IDs and directories must remain stable after import; migrate their lock
records and links explicitly before renaming a source.

## Safety and verification

Check/diff exit codes: 0 unchanged, 1 differences, 2 failure. They fetch GitHub
on demand into memory and do not modify installed files. No checks are scheduled.
Import/update preflight local edits, missing upstream skills, attribution files
and name/link collisions; they preserve skill bytes and executable bits. Changes
are staged and filesystem exceptions during publication trigger rollback. This
is not crash recovery or a concurrent-writer locking mechanism; run one mutation
at a time. Upstream archive links inside selected skills are rejected.

Uninstall removes only registered matching symlinks, retaining shared sources.
A replaced link or real directory is a conflict. The manager never commits or
pushes. Run `python3 .bin/tests/test-skill-manager.py` for offline integration tests.

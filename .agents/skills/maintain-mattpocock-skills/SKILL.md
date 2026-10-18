---
name: maintain-mattpocock-skills
description: Check, compare, update or selectively import skills from mattpocock/skills into these dotfiles. Use for requests to maintain the vendored mattpocock collection or add another upstream skill.
---

Use the dotfiles script `.bin/mattpocock-skills` from the dotfiles root. Shared upstream files live in `.agents/skills/mattpocock/`; `upstream.json` records the source repository, per-skill commit and SHA-256 hashes. Codex, codex-2nd and Claude use relative directory symlinks. Our maintenance instructions and script live outside the upstream tree.

## Review first

- Run `.bin/mattpocock-skills check` (also the default action). It fetches upstream but does not alter installed files. Exit 0 means no differences for selected installed skills; 1 means differences or broken links; 2 means failure. New unimported skills are listed separately and do not alone make the check fail.
- Run `.bin/mattpocock-skills list` to discover upstream skill paths and installation status.
- Run `.bin/mattpocock-skills diff [skills/category/name ...] --ref COMMIT` to compare local content against a specific upstream revision. Explain substantive behavior changes, added references, invocation metadata, and local changes. The manifest hashes distinguish local changes from upstream changes; the displayed patch compares local files to upstream.
- Check/diff report metadata changes separately. If LICENSE or a category README changed, inspect that upstream file at the reported commit before applying an update.

## Apply the requested selection

Updating or importing requires the user's instruction; a request to check does not authorize updates. Existing explicit update/import authorization is sufficient. Pin the reviewed commit with `--ref` so the applied version matches the review.

```sh
.bin/mattpocock-skills update skills/productivity/grilling --ref COMMIT
.bin/mattpocock-skills update --category productivity --ref COMMIT
.bin/mattpocock-skills import skills/engineering/SKILL-NAME --ref COMMIT
```

`import --category productivity` is for an entirely unimported category; for later additions, list and import the new skill paths explicitly. `update` without paths updates all installed skills. Upstream deletions require manual review; the script never automatically removes an installed skill. Files, references and `agents/openai.yaml` are imported unchanged. Dependencies outside a selected skill are not automatically imported: inspect its references and explain any required additional selection.

Local modifications and conflicting client links stop updates before writes. Show the conflict and agree how to preserve or reconcile it; never delete local edits to make the script pass. Do not edit upstream skill files to adapt them to this environment. Keep local adaptation outside the collection and obey the user's existing agent/delegation rules.

For each new skill, explicitly allow its symlink in `.gitignore` under `.codex/skills`, `.codex-2nd/skills` and `.claude/skills`. The vendored source tree is already allowlisted. Check all three links resolve to the shared source, inspect `git diff --check` and `git status --short --untracked-files=all`, and run the script tests with `python3 .bin/tests/test-mattpocock-skills.py`. Preserve upstream invocation settings. Newly installed skills are available on a subsequent turn after discovery refresh.

Do not schedule checks, commit or push unless requested. Report the reviewed/applied commit, selected skills, remaining differences and verification.

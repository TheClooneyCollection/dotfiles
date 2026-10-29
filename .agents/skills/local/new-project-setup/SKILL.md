---
name: new-project-setup
description: Set up a new project repository with the user's conventions (Git, conventional commits, AGENTS.md, docs layout, versioning). Use when the user asks to start, create, scaffold or initialise a new project or repo, or to bring an empty directory up to their repo conventions.
---

Lay down the **skeleton**: Git, agent instructions, docs layout and versioning rules. No language, framework or build tooling; those come later, from the project itself. The templates live in [`templates/`](templates/) next to this file.

**Swift or Xcode** app: also follow [`references/swift.md`](references/swift.md); read it before step 1, since it adds questions.

## 1. Ask once

Ask everything in one message, each with its default, and accept "defaults" as an answer:

- **Name** and a one-sentence **description**.
- **Target directory**: default the current one.
- **Versioning**: `calver` (`vYYYY.MM.X`, snapshot labels), `semver`, or `beta` (`v0.MINOR.PATCH` derived from commits). Default `calver`.
- **Changelog notes** (one Markdown note file per feat/fix commit, built into `CHANGELOG.md`): default on.
- **License**: default none. If chosen, which one and the copyright holder.
- **`.gitignore` style**: `standard` (ignore junk) or `allowlist` (ignore everything, track by exception). Default `standard`.
- **Docs language**: default English.
- **GitHub remote**: default none.

## 2. Check the target

Look at the target directory before writing. If it already has a `.git` or any file that a template would replace, list them and ask how to proceed. The step is done when every template path is known to be free or the user has said what to do with each clash.

## 3. Write the skeleton

1. `git init -b main`.
2. Copy the templates, keeping their paths, with these renames: `gitignore-<style>` becomes `.gitignore` (drop the other one), `versioning/` is consumed rather than copied, and `swift/` is used only through `references/swift.md`.
3. Fill the placeholders: `{{PROJECT_NAME}}`, `{{DESCRIPTION}}`, and in `AGENTS.md` replace `{{VERSIONING}}` with the body of `versioning/<scheme>.md`.
4. Changelog notes on:
   - Keep `docs/development/changelog-notes/`, `tools/build_changelog.py`, `tools/test_build_changelog.py` and `scripts/refresh-changelog.sh` (executable).
   - Write `tools/build_changelog.json` as `{"scheme": "<scheme>"}`. The defaults generate `CHANGELOG.md` at the root; the other settings (`json`, `version_file` outputs, `notes_dir`) are documented at the top of `build_changelog.py`, so add them only when the project asks.
   - Add `- [Changelog notes](changelog-notes/README.md): one note file per feat/fix commit.` to `docs/development/README.md`.
   - Replace `{{CHANGELOG}}` in `AGENTS.md` with `Every feat and fix commit adds its own changelog note file, then refreshes CHANGELOG.md: see [docs/development/changelog-notes/README.md](docs/development/changelog-notes/README.md).`
   - Run `python3 tools/test_build_changelog.py` and `python3 tools/build_changelog.py` (writes the empty `CHANGELOG.md`).

   Notes off: delete that folder, `tools/`, `scripts/` and the `{{CHANGELOG}}` line.
5. License chosen: fetch the official text (for example `gh api licenses/mit --jq .body`, or the license's own site for PolyForm), fill year and holder, save as `LICENSE`, and keep the README's `## License` section. No license: remove that section.
6. Translate the prose of the docs into the docs language if it is not English; keep file names, commands and commit types in English.

Done when `grep -rn --exclude-dir=.git '{{' .` in the target finds nothing and the tree matches the layout below (brackets mark optional files).

```
AGENTS.md  CLAUDE.md  README.md  .gitignore  [LICENSE]  [CHANGELOG.md]
[tools/build_changelog.py  tools/build_changelog.json  tools/test_build_changelog.py]
[scripts/refresh-changelog.sh]
docs/README.md                      # lists the folders
docs/technical/README.md            # each folder's README indexes its docs
docs/development/README.md
[docs/development/changelog-notes/README.md]   # note format; notes sit beside it
docs/product/README.md
docs/product/ideas.md
docs/research/README.md
docs/decisions/README.md            # decision format and index
```

## 4. Commit and publish

1. Show the user the tree (`git status --short --untracked-files=all`) and commit it as `chore: initial project skeleton`.
2. Remote requested: confirm the repository name and visibility (default private) first, since creating it is outward-facing, then `gh repo create <name> --private --source . --push`.

Report the path, the choices made and the first commit hash.

## Maintaining the changelog tools

`templates/tools/` and `templates/scripts/` hold the canonical changelog builder; projects vendor copies. After changing them here, copy them into projects that use them (StoneAge keeps its own settings in `tools/build_changelog.json` and its own extra tests in `tools/test_changelog_history.py`) and run each project's `python3 tools/test_build_changelog.py` and `python3 tools/build_changelog.py --check`.

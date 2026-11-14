# Changelog notes

Every `feat` and `fix` commit adds its own note file in this folder, `<YYYYMMDDTHHMMSSZ>-<slug>.md` (UTC timestamp, lowercase ASCII slug). One file per commit keeps parallel branches free of changelog conflicts. `tools/build_changelog.py` builds `CHANGELOG.md` from the first-parent history of `main`, using the note's title and bullets, or the commit subject when a commit has no note.

```markdown
---
subject: "feat(scope): exact commit subject"
title: "Short user-facing title"
---

- What changed, in terms of visible behaviour and where to find it.
- Say plainly what is still missing or incomplete.
```

The `subject` matches the commit subject exactly. The frontmatter holds exactly these two JSON-quoted strings; the body is `- ` items with two-space continuation lines.

## Workflow

1. Write the note, test, and commit it with the change.
2. Run `./scripts/refresh-changelog.sh`. It regenerates `CHANGELOG.md` and amends only the generated files into the commit just made, so run it only on your own unpushed commit; for a shared commit, regenerate and commit `chore(changelog): refresh` separately.
3. `python3 tools/build_changelog.py --check` fails when the generated files are stale.

Edit notes, never `CHANGELOG.md`. When a rebase conflicts on generated files, take either side and regenerate in every rebased commit: `git rebase main --exec 'python3 tools/build_changelog.py && git add -A CHANGELOG.md && git commit --amend --no-edit -q'`.

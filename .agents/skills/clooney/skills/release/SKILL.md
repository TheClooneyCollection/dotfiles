---
name: release
description: Cut a release of the current repo by hand: derive the version from its commits, prepare and tag it, publish the GitHub release, then run the repo's own post-release steps. Use when the user says "release", "cut a release", "ship vX.Y.Z", or 发版.
---

The repo's AGENTS.md (or CLAUDE.md) is the source of truth: `## Versioning` gives the scheme, `## Release` gives version files, checks, prep commit, title, notes style and post-release steps. No `## Release` section: ask for those fields in one message, defaults in brackets, and write the section first.

1. **Preflight.** On `main`, clean tree, level with `origin/main`, CI green on HEAD (`gh run list --commit $(git rev-parse HEAD)`). Done: all four hold, or the user said to go anyway.
2. **Version.** From the commits since the latest tag, by the scheme. A changelog builder in the repo (`tools/build_changelog.py`) is authoritative. Show the version and the commits behind it. If the user wants a version the commits don't give, say so and agree how; for a new major, the prep commit is `feat!: ...` with its changelog note. Done: the user confirmed the version.
3. **Prepare.** Update each version file, refresh generated files, run every listed check, and make one prep commit. Done: checks pass and `git show --stat HEAD` has only release files.
4. **Tag and push.** `git tag -a vX.Y.Z -m "vX.Y.Z"`, then `git push --atomic origin main vX.Y.Z` so CI never sees the bump without its tag. The confirmed release is permission to push. Done: `git ls-remote --tags origin vX.Y.Z` shows it.
5. **Publish.** `gh release create vX.Y.Z --title "<title>" --notes-file <notes>`. Notes: this version's changelog section in the repo's notes style, then the compare link `<repo>/compare/vPREV...vX.Y.Z` (none for the first release). Done: `gh release view vX.Y.Z` shows it.
6. **After release.** Run each listed post-release step. Report the version, the release URL and each step's result.

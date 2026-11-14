#!/bin/sh
# Run after a successful commit with Markdown changelog notes. Amend only generated files, preserving
# unrelated staged and unstaged work. No hash is stored in any output.
set -eu
cd "$(dirname "$0")/.."
IFS='
'
set -f
outputs=$(python3 tools/build_changelog.py --outputs)
if [ -n "$(git status --porcelain -- $outputs)" ]; then
  echo "Commit or preserve existing edits to generated changelog files before refreshing: $(echo $outputs)" >&2
  exit 1
fi
python3 tools/build_changelog.py
if [ -n "$(git status --porcelain -- $outputs)" ]; then
  git add -- $outputs
  git commit --amend --no-edit --only -- $outputs
fi
python3 tools/build_changelog.py --check

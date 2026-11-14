#!/usr/bin/env bash
# Lint the app and test sources with SwiftLint and SwiftFormat (read-only).
# Run from anywhere: ./scripts/lint.sh (it works in the folder above this script).
set -euo pipefail

cd "$(dirname "$0")/.."

SOURCES=({{APP}} {{APP}}Tests)
status=0

# No --strict: line_length warnings (80) are a soft target; errors (120) fail.
if command -v swiftlint >/dev/null 2>&1; then
    echo "==> SwiftLint $(swiftlint version)"
    swiftlint lint --quiet || status=1
else
    echo "error: swiftlint not found. Install it with: brew install swiftlint" >&2
    status=1
fi

if command -v swiftformat >/dev/null 2>&1; then
    echo "==> SwiftFormat $(swiftformat --version)"
    swiftformat --lint --config .swiftformat "${SOURCES[@]}" || status=1
else
    echo "error: swiftformat not found. Install it with: brew install swiftformat" >&2
    status=1
fi

exit "$status"

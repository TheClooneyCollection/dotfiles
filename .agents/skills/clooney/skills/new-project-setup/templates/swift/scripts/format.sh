#!/usr/bin/env bash
# Format the app and test sources in place with SwiftFormat.
# Run from anywhere: ./scripts/format.sh (it works in the folder above this script).
set -euo pipefail

cd "$(dirname "$0")/.."

SOURCES=({{APP}} {{APP}}Tests)

if ! command -v swiftformat >/dev/null 2>&1; then
    echo "error: swiftformat not found. Install it with: brew install swiftformat" >&2
    exit 1
fi

echo "==> SwiftFormat $(swiftformat --version)"
swiftformat "${SOURCES[@]}" --config .swiftformat --quiet
echo "Formatted: ${SOURCES[*]}"

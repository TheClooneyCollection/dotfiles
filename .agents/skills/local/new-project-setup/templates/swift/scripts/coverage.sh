#!/usr/bin/env bash
# Run the tests with coverage and report app coverage, overall and without the UI.
# Run from anywhere: ./scripts/coverage.sh [path/to/existing.xcresult]
# With a result bundle, it skips the test run and only reports.
set -euo pipefail

cd "$(dirname "$0")/.."

APP_TARGET="{{APP}}.app"
# Excluded from the non-UI number: SwiftUI views and the app entry point.
UI_PATTERN='/Views/|/{{APP}}App\.swift$'

if ! command -v jq >/dev/null 2>&1; then
    echo "error: jq not found. Install it with: brew install jq" >&2
    exit 1
fi

if [[ $# -gt 0 ]]; then
    RESULT="$1"
else
    RESULT="$(mktemp -d)/Tests.xcresult"
    echo "==> Running tests with coverage into $RESULT"
    xcodebuild test \
        -project {{APP}}.xcodeproj \
        -scheme {{APP}} \
        -destination 'platform=iOS Simulator,name={{SIMULATOR}}' \
        -enableCodeCoverage YES \
        -resultBundlePath "$RESULT" \
        -quiet
fi

# Only the app target counts: Xcode's headline number also includes the test bundle itself.
REPORT="$(xcrun xccov view --report --json "$RESULT")"

# Prints one section of the report as aligned columns.
section() {
    jq -r --arg target "$APP_TARGET" --arg ui "$UI_PATTERN" "
        [.targets[] | select(.name == \$target) | .files[]] as \$files
        | (\$files | map(select(.path | test(\$ui) | not))) as \$logic
        | $1
    " <<<"$REPORT" | column -t -s $'\t'
}

echo "==> Coverage for $APP_TARGET"
section '
    def pct: if .executable == 0 then 0 else (.covered / .executable * 1000 | floor / 10) end;
    def total: { covered: (map(.coveredLines) | add // 0), executable: (map(.executableLines) | add // 0) };
    def row($name): "\($name)\t\(.covered)/\(.executable)\t\(pct)%";
    ($files | total | row("All app code")), ($logic | total | row("Without UI"))
'

echo
echo "==> Non-UI files under 100%"
section '
    $logic
    | map(select(.lineCoverage < 1))
    | sort_by(.lineCoverage)[]
    | "\(.lineCoverage * 100 | floor)%\t\(.coveredLines)/\(.executableLines)\t\(.path | sub(".*/{{APP}}/"; ""))"
'

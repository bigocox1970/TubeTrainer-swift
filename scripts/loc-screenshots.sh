#!/usr/bin/env bash
# Capture localized screenshots of the main app screens for one language.
#
# Usage:  scripts/loc-screenshots.sh <lang> [simulatorUDID]
#   e.g.  scripts/loc-screenshots.sh es
#         scripts/loc-screenshots.sh de
#         scripts/loc-screenshots.sh pt-br
#
# Runs the TubeTrainerUITests/LocalizationScreenshots harness in the given
# language (seeded sample data, onboarding skipped) and writes PNGs to
# screenshots-loc/<lang>/. Defaults to the currently-booted simulator.
set -euo pipefail
cd "$(dirname "$0")/.."

LANG_CODE="${1:-es}"
SIM_ID="${2:-$(xcrun simctl list devices booted -j | python3 -c 'import json,sys; d=json.load(sys.stdin); print(next((x["udid"] for v in d["devices"].values() for x in v if x.get("state")=="Booted"), ""))')}"

if [ -z "$SIM_ID" ]; then
  echo "No booted simulator. Boot one (open Simulator, or: xcrun simctl boot <udid>) or pass a UDID as arg 2." >&2
  exit 1
fi

OUT="$(pwd)/screenshots-loc/$LANG_CODE"
rm -rf "$OUT"; mkdir -p "$OUT"
RESULT="$(mktemp -d)/loc.xcresult"

echo "Capturing '$LANG_CODE' screenshots on simulator $SIM_ID ..."
xcodegen generate >/dev/null
TEST_RUNNER_TT_UITEST_LANG="$LANG_CODE" TEST_RUNNER_TT_SHOT_DIR="$OUT" \
  xcodebuild test \
    -project TubeTrainer.xcodeproj -scheme TubeTrainer \
    -destination "platform=iOS Simulator,id=$SIM_ID" \
    -only-testing:TubeTrainerUITests/LocalizationScreenshots/testMainScreens \
    -resultBundlePath "$RESULT" >/dev/null

echo "Done. Screenshots in: $OUT"
ls -1 "$OUT"

#!/usr/bin/env bash
# Sync DISPLAY_NAME into strings.xml, build, then restore strings.xml for git.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

CONNECTIQ_SDK="${CONNECTIQ_SDK:-$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.2.0-2026-06-09-92a1605b2}"
MONKEYBRAINS="$CONNECTIQ_SDK/bin/monkeybrains.jar"
DEVELOPER_KEY="${DEVELOPER_KEY:-$HOME/garmin-dev/developer_key}"
DEVICE="${DEVICE:-fr965}"
OUT="${OUT:-$ROOT/garmin.prg}"

cleanup() {
  python3 "$ROOT/scripts/sync-strings.py" --restore
}
trap cleanup EXIT

python3 "$ROOT/scripts/sync-strings.py"

java -Xms1g -Dfile.encoding=UTF-8 -Dapple.awt.UIElement=true \
  -jar "$MONKEYBRAINS" \
  -o "$OUT" \
  -f "$ROOT/monkey.jungle" \
  -y "$DEVELOPER_KEY" \
  -d "$DEVICE" \
  -w -r

echo "Built $OUT"

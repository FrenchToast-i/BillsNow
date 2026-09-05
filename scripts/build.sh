#!/usr/bin/env bash
#
# Builds BillsNow for a real device signed with your Apple ID team, the
# normal "I want to install it on my own iPad" path. Open the project in
# Xcode and set your Team once under:
#     BillsNow target -> Signing & Capabilities -> Team
#   BillsWidget target -> Signing & Capabilities -> Team
# …or pass it here:
#
#   TEAM_ID=ABCDE12345 ./scripts/build.sh
#
# The App Group entitlement (group.com.billsnow.shared) is shared by the app
# and the widget so both can read the same cached game data.
#
set -euo pipefail
cd "$(dirname "$0")/.."

TEAM_ID="${TEAM_ID:-}"
DERIVED="${DERIVED:-build-signed}"

if [ -z "$TEAM_ID" ]; then
  echo "✗ TEAM_ID not set (your Apple Developer team id, e.g. from Xcode > Settings > Accounts)." >&2
  echo "  Alternatively open BillsNow.xcodeproj in Xcode and Run from there." >&2
  exit 1
fi

echo "▸ Building for device with team $TEAM_ID…"
xcodebuild \
  -project BillsNow.xcodeproj \
  -scheme BillsNow \
  -configuration Release \
  -sdk iphoneos \
  -derivedDataPath "$DERIVED" \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  CODE_SIGN_STYLE=Automatic \
  build

APP="$DERIVED/Build/Products/Release-iphoneos/BillsNow.app"
echo "✔ Built: $APP"
echo "  Install over USB from Xcode (Window > Devices and Simulators) or use Sideloadly with the .ipa."

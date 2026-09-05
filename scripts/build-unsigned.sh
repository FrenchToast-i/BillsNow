#!/usr/bin/env bash
#
# Builds BillsNow (app + live-score widget extension) for a real device
# WITHOUT code signing, then packages an .ipa you can install however you
# like (TrollStore, Filza + ldid on a jailbroken device, Sideloadly with a
# free Apple ID, ...). The widget extension ends up embedded inside the app
# bundle automatically.
#
# Requires: macOS with Xcode (13 or newer) installed.
# Usage:     ./scripts/build-unsigned.sh
# Output:    build/BillsNow.ipa  and  build/BillsNow.app
#
set -euo pipefail
cd "$(dirname "$0")/.."

SCHEME="${SCHEME:-BillsNow}"
DERIVED="${DERIVED:-build}"

echo "▸ Cleaning previous build output…"
rm -rf "$DERIVED"

echo "▸ Building $SCHEME (Release, iphoneos, unsigned)…"
xcodebuild \
  -project BillsNow.xcodeproj \
  -scheme "$SCHEME" \
  -configuration Release \
  -sdk iphoneos \
  -derivedDataPath "$DERIVED" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  build

APP="$DERIVED/Build/Products/Release-iphoneos/BillsNow.app"
if [ ! -d "$APP" ]; then
  echo "✗ App bundle not found at $APP" >&2
  exit 1
fi
if [ ! -d "$APP/PlugIns/BillsWidget.appex" ]; then
  echo "✗ Widget extension missing from the app bundle (PlugIns/BillsWidget.appex)." >&2
  exit 1
fi

echo "▸ Packaging BillsNow.ipa…"
IPA_DIR="$DERIVED/ipa"
rm -rf "$IPA_DIR"
mkdir -p "$IPA_DIR/Payload"
cp -R "$APP" "$IPA_DIR/Payload/"
(cd "$IPA_DIR" && zip -qry "../BillsNow.ipa" Payload)

echo
echo "✔ Done:"
echo "    app : $APP"
echo "    ipa : $DERIVED/BillsNow.ipa"
echo
echo "Widget extension inside: $(ls "$APP/PlugIns")"

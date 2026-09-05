#!/usr/bin/env bash
#
# Signs the built BillsNow.app (main binary + embedded widget extension) with
# ldid and the project entitlements, then repackages a signed .ipa.
#
# This is what makes the "download one file, tap Install in Filza" flow work
# on a jailbroken device: both binaries end up carrying the App Group
# entitlement (group.com.billsnow.shared), so the widget can read the cached
# game snapshot. No terminal / ldid needed on the iPad afterwards.
#
# ldid is fetched automatically if it isn't on PATH (prebuilt Procursus
# binary, ~1 MB). Works on macOS (CI) and Linux.
#
# Usage:  ./scripts/sign-with-ldid.sh
# Output: build/BillsNow-signed.ipa   (and the .app bundle is signed in place)
#
set -euo pipefail
cd "$(dirname "$0")/.."

DERIVED="${DERIVED:-build}"
APP="$DERIVED/Build/Products/Release-iphoneos/BillsNow.app"
APPEX="$APP/PlugIns/BillsWidget.appex"
IPA_OUT="$DERIVED/BillsNow-signed.ipa"
GROUP="group.com.billsnow.shared"

# --- locate ldid ------------------------------------------------------------
LDID="$(command -v ldid || true)"
if [ -z "$LDID" ]; then
  TOOLS="$DERIVED/tools"
  mkdir -p "$TOOLS"
  case "$(uname -s)-$(uname -m)" in
    Linux-x86_64)  L=ldid_linux_x86_64  ;;
    Linux-aarch64) L=ldid_linux_aarch64 ;;
    Darwin-x86_64) L=ldid_macosx_x86_64 ;;
    Darwin-arm64)  L=ldid_macosx_arm64  ;;
    *) echo "✗ no prebuilt ldid for $(uname -s)-$(uname -m); install ldid and retry" >&2; exit 1 ;;
  esac
  LDID="$TOOLS/ldid"
  if [ ! -x "$LDID" ]; then
    echo "▸ Downloading $L …"
    curl -fsSL -o "$LDID" \
      "https://github.com/ProcursusTeam/ldid/releases/download/v2.1.5-procursus7/$L"
    chmod +x "$LDID"
  fi
fi

# --- sanity checks ----------------------------------------------------------
[ -d "$APP" ]   || { echo "✗ app bundle missing at $APP — run build-unsigned.sh first" >&2; exit 1; }
[ -d "$APPEX" ] || { echo "✗ widget extension missing at $APPEX" >&2; exit 1; }
grep -q "com.apple.widgetkit-extension" "$APPEX/Info.plist" \
  || { echo "✗ appex Info.plist is not a WidgetKit extension" >&2; exit 1; }

# --- sign -------------------------------------------------------------------
# Note: ldid takes the entitlements path ATTACHED to -S ("-Sent.plist file");
# a space-separated "-S ent.plist file" makes it read the plist as the Mach-O.
echo "▸ Signing main binary…"
"$LDID" -S"BillsNow/BillsNow.entitlements" "$APP/BillsNow"
echo "▸ Signing widget extension binary…"
"$LDID" -S"BillsWidget/BillsWidget.entitlements" "$APPEX/BillsWidget"

# --- verify ----------------------------------------------------------------
echo "▸ Verifying embedded entitlements:"
"$LDID" -e "$APP/BillsNow" | grep -o "group\.[a-zA-Z.]*" || true
"$LDID" -e "$APPEX/BillsWidget" | grep -o "group\.[a-zA-Z.]*" || true
"$LDID" -e "$APP/BillsNow" | grep -q "$GROUP" \
  || { echo "✗ App Group missing from main binary" >&2; exit 1; }
"$LDID" -e "$APPEX/BillsWidget" | grep -q "$GROUP" \
  || { echo "✗ App Group missing from widget binary" >&2; exit 1; }

# --- repackage --------------------------------------------------------------
echo "▸ Packaging $IPA_OUT …"
IPA_DIR="$DERIVED/ipa-signed"
rm -rf "$IPA_DIR"
mkdir -p "$IPA_DIR/Payload"
cp -R "$APP" "$IPA_DIR/Payload/"
(cd "$IPA_DIR" && zip -qry "../BillsNow-signed.ipa" Payload)

echo
echo "✔ Signed ipa ready: $IPA_OUT"
echo "  Install: copy to the iPad → open in Filza → Install (no re-signing needed)."
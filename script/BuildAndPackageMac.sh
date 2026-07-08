#!/bin/bash
#
# Build, sign, notarize and package the macOS version of Dink Smallwood HD.
# Runs ON the Mac (normally driven from Windows by script/BuildMac.bat over ssh).
#
# Usage: BuildAndPackageMac.sh [nonotarize]
#   nonotarize - stop after signing and DMG creation (for quick tests)
#
# Requirements on this Mac (one-time setup):
#   - Xcode with command line tools
#   - SDL2.framework and SDL2_mixer.framework in ~/Library/Frameworks
#     (universal DMG releases from libsdl.org, see INSTALL.md)
#   - "Developer ID Application" identity in the login keychain
#   - Keychain password in ~/.rtdink_keychain_pass (chmod 600) so this can
#     run over ssh where the keychain shows up locked. Not needed when run
#     from a normal GUI terminal session.
#   - notarytool credentials profile (once):
#       xcrun notarytool store-credentials "$NOTARY_PROFILE" \
#         --apple-id <appleid email> --team-id 7DA5SJEYK8 \
#         --password <app-specific password from appleid.apple.com>

set -euo pipefail

APP_NAME="Dink Smallwood HD"
# CODESIGN_IDENTITY=- gives an unsigned-style ad-hoc build for pipeline testing
IDENTITY="${CODESIGN_IDENTITY:-Developer ID Application: Robinson Technologies Corporation (7DA5SJEYK8)}"
NOTARY_PROFILE="${NOTARY_PROFILE:-rtsoft-notary}"
TS_FLAG="--timestamp"
[ "$IDENTITY" = "-" ] && TS_FLAG=""

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OSX_DIR="$SCRIPT_DIR/../OSX"
RELEASE_DIR="$OSX_DIR/build/Release"
APP="$RELEASE_DIR/$APP_NAME.app"
OUT_DIR="$SCRIPT_DIR/builds/mac"
DMG="$OUT_DIR/DinkSmallwoodHD.dmg"

NO_NOTARIZE=
[ "${1:-}" = "nonotarize" ] && NO_NOTARIZE=1

echo "============================================"
echo " Dink Smallwood HD - Mac Builder"
echo " App: $APP_NAME   Notarize: $([ -n "$NO_NOTARIZE" ] && echo NO || echo yes)"
echo "============================================"

# ---------- keychain ----------
# Over ssh the login keychain is locked; unlock it so codesign/notarytool work.
# (ad-hoc signing needs no keychain)
if [ "$IDENTITY" != "-" ] && ! security show-keychain-info login.keychain >/dev/null 2>&1; then
    if [ -f "$HOME/.rtdink_keychain_pass" ]; then
        echo "[keychain] Unlocking login keychain..."
        security unlock-keychain -p "$(cat "$HOME/.rtdink_keychain_pass")" login.keychain
    else
        echo "[keychain] Keychain is locked and ~/.rtdink_keychain_pass not found."
        echo "           Trying interactive unlock (works in a terminal, not over plain ssh):"
        security unlock-keychain login.keychain
    fi
fi
# Keep it unlocked for the duration of the build (timestamps + notarize can be slow)
security set-keychain-settings -lut 7200 login.keychain 2>/dev/null || true

# ---------- build ----------
echo "[1/6] Building Release (universal)..."
cd "$OSX_DIR"
xcodebuild -project RTDink.xcodeproj -configuration Release clean build > /tmp/rtdink_build.log 2>&1 || {
    echo "ERROR: build failed, last lines of /tmp/rtdink_build.log:"
    tail -30 /tmp/rtdink_build.log
    exit 1
}
lipo -info "$APP/Contents/MacOS/$APP_NAME"

# ---------- embed frameworks ----------
echo "[2/6] Embedding SDL2 frameworks..."
FW_DST="$APP/Contents/Frameworks"
rm -rf "$FW_DST"
mkdir -p "$FW_DST"
for FW in SDL2 SDL2_mixer; do
    SRC="$HOME/Library/Frameworks/$FW.framework"
    [ -d "$SRC" ] || { echo "ERROR: $SRC not found (see INSTALL.md)"; exit 1; }
    ditto "$SRC" "$FW_DST/$FW.framework"
    # headers aren't needed at runtime and just bloat the bundle
    rm -rf "$FW_DST/$FW.framework/Headers" "$FW_DST/$FW.framework/Versions/A/Headers"
done

# ---------- sign ----------
echo "[3/6] Code signing (Developer ID, hardened runtime)..."
# nested dylibs/frameworks first (SDL2_mixer ships optional codec dylibs on some releases)
find "$FW_DST" -name "*.dylib" -print0 2>/dev/null | while IFS= read -r -d '' LIB; do
    codesign --force --options runtime $TS_FLAG -s "$IDENTITY" "$LIB"
done
codesign --force --options runtime $TS_FLAG -s "$IDENTITY" "$FW_DST/SDL2.framework"
codesign --force --options runtime $TS_FLAG -s "$IDENTITY" "$FW_DST/SDL2_mixer.framework"
codesign --force --options runtime $TS_FLAG -s "$IDENTITY" "$APP"
codesign --verify --deep --strict "$APP"
echo "Signature OK."

# ---------- DMG ----------
echo "[4/6] Building DMG..."
mkdir -p "$OUT_DIR"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
ditto "$APP" "$STAGE/$APP_NAME.app"
cp "$OSX_DIR/readme.txt" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
rm -f "$DMG"
hdiutil create -volname "$APP_NAME" -srcfolder "$STAGE" -format UDZO -imagekey zlib-level=9 "$DMG"
codesign --force $TS_FLAG -s "$IDENTITY" "$DMG"

if [ -n "$NO_NOTARIZE" ]; then
    echo "Skipping notarization (nonotarize). DMG at: $DMG"
    exit 0
fi

# ---------- notarize ----------
echo "[5/6] Notarizing (this waits on Apple, usually a few minutes)..."
SUBMIT_OUT="$(xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait 2>&1)" || {
    echo "$SUBMIT_OUT"
    echo "ERROR: notarization submit failed."
    exit 1
}
echo "$SUBMIT_OUT"
if ! echo "$SUBMIT_OUT" | grep -q "status: Accepted"; then
    SUB_ID="$(echo "$SUBMIT_OUT" | awk '/^  id: /{print $2; exit}')"
    echo "ERROR: notarization not accepted. Log:"
    [ -n "$SUB_ID" ] && xcrun notarytool log "$SUB_ID" --keychain-profile "$NOTARY_PROFILE" || true
    exit 1
fi

# ---------- staple + verify ----------
echo "[6/6] Stapling and verifying..."
xcrun stapler staple "$DMG"
xcrun stapler validate "$DMG"
spctl --assess --type open --context context:primary-signature -vv "$DMG"

echo "============================================"
echo " DONE: $DMG ($(du -h "$DMG" | cut -f1 | tr -d ' '))"
echo "============================================"

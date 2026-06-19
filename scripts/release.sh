#!/usr/bin/env bash
#
# FocusNotch release pipeline: build (Release) → sign → DMG → notarize → staple.
#
# Prerequisites for a fully notarized build (required for distribution):
#   1. A paid Apple Developer Program membership.
#   2. A "Developer ID Application" certificate. Create it in
#      Xcode → Settings → Accounts → Manage Certificates → + → Developer ID Application.
#   3. A notarytool keychain profile, created once with:
#        xcrun notarytool store-credentials "FocusNotchNotary" \
#          --apple-id "you@example.com" \
#          --team-id "YOURTEAMID" \
#          --password "app-specific-password"   # from appleid.apple.com
#
# Usage:
#   FN_SIGN_ID="Developer ID Application: Your Name (TEAMID)" \
#   FN_NOTARY_PROFILE="FocusNotchNotary" \
#   ./scripts/release.sh
#
#   Omit FN_NOTARY_PROFILE to build a signed (but un-notarized) DMG for testing.
#   FN_SIGN_ID may be the identity name or its 40-char SHA-1 hash.
set -euo pipefail
cd "$(dirname "$0")/.."

APP_NAME="FocusNotch"
SCHEME="FocusNotch"
CONFIG="Release"
DIST="dist"
DD="$DIST/DerivedData"
ENTITLEMENTS="Sources/Resources/FocusNotch.entitlements"

SIGN_ID="${FN_SIGN_ID:-Developer ID Application}"
NOTARY_PROFILE="${FN_NOTARY_PROFILE:-}"

echo "▶ Generating project…"
xcodegen generate >/dev/null

echo "▶ Building $CONFIG (signing as: $SIGN_ID)…"
rm -rf "$DD"
xcodebuild -project "$APP_NAME.xcodeproj" -scheme "$SCHEME" -configuration "$CONFIG" \
  -derivedDataPath "$DD" \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY="$SIGN_ID" \
  CODE_SIGN_ENTITLEMENTS="$ENTITLEMENTS" \
  OTHER_CODE_SIGN_FLAGS="--timestamp --options runtime" \
  build | grep -E "error:|warning:|BUILD" || true

APP="$DD/Build/Products/$CONFIG/$APP_NAME.app"
[ -d "$APP" ] || { echo "✗ Build failed — $APP not found"; exit 1; }

VERSION=$(defaults read "$PWD/$APP/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo "1.0.0")
DMG="$DIST/$APP_NAME-$VERSION.dmg"

echo "▶ Verifying code signature…"
codesign --verify --strict --verbose=2 "$APP"

echo "▶ Building DMG…"
STAGING=$(mktemp -d)
cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"
rm -f "$DMG"
hdiutil create -volname "$APP_NAME" -srcfolder "$STAGING" -ov -format UDZO "$DMG" >/dev/null
rm -rf "$STAGING"
echo "  → $DMG"

if [ -n "$NOTARY_PROFILE" ]; then
  echo "▶ Notarizing (a few minutes)…"
  xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait
  echo "▶ Stapling…"
  xcrun stapler staple "$DMG"
  xcrun stapler validate "$DMG"
  echo "✓ Notarized DMG ready: $DMG"
else
  echo "⚠ FN_NOTARY_PROFILE not set → DMG is signed but NOT notarized."
  echo "  It installs, but other Macs need right-click → Open the first time."
  echo "  Set up notarization (see header of this script) for public distribution."
fi

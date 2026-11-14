#!/bin/zsh
# Builds a signed, notarized and stapled DMG ready for distribution.
#
# One-time setup (stores your Apple ID app-specific password in the Keychain):
#   xcrun notarytool store-credentials "YUCE-notary" --apple-id <APPLE_ID> --team-id MPRDU9BAS3
#
# Usage:
#   ./release.sh            → dist/YUCE-Cleaner-<version>.dmg
set -e
cd "$(dirname "$0")"

export VERSION="${VERSION:-1.2.1}"
export SIGN_ID="${SIGN_ID:-Developer ID Application: BARIS YUCE (MPRDU9BAS3)}"
NOTARY_PROFILE="${NOTARY_PROFILE:-YUCE-notary}"
APP="YUCE Cleaner.app"
DMG="dist/YUCE-Cleaner-$VERSION.dmg"

./build.sh

# DMG with an Applications shortcut for drag-and-drop install
rm -rf dist && mkdir -p dist
STAGE="$(mktemp -d)"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "YUCE Cleaner" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null
rm -rf "$STAGE"
codesign --force --timestamp --sign "$SIGN_ID" "$DMG"

if [[ "$SKIP_NOTARIZE" == "1" ]]; then
  echo "Signed (not notarized): $DMG"
  exit 0
fi

xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$DMG"
xcrun stapler validate "$DMG"
spctl --assess --type open --context context:primary-signature -v "$DMG"
shasum -a 256 "$DMG"
echo "Ready: $DMG"

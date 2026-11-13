#!/bin/zsh
# Builds "YUCE Mac Cleaner.app" (universal: Apple silicon + Intel) from the Swift sources.
#
#   ./build.sh                        ad-hoc signed, for local use
#   SIGN_ID="Developer ID Application: …" ./build.sh
#                                     signed with hardened runtime, ready for notarization
set -e
cd "$(dirname "$0")"

VERSION="${VERSION:-1.1.0}"
BUILD="$(git rev-list --count HEAD 2>/dev/null || echo 1)"

APP="YUCE Mac Cleaner.app"
EXE="YUCEMacCleaner"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

TMP="$(mktemp -d)"
for ARCH in arm64 x86_64; do
  swiftc -O -parse-as-library -swift-version 5 \
    -target "$ARCH-apple-macos14.0" \
    Sources/*.swift -o "$TMP/$EXE-$ARCH"
done
lipo -create "$TMP/$EXE-arm64" "$TMP/$EXE-x86_64" -output "$APP/Contents/MacOS/$EXE"
rm -rf "$TMP"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>YUCE Mac Cleaner</string>
  <key>CFBundleDisplayName</key><string>YUCE Mac Cleaner</string>
  <key>CFBundleIdentifier</key><string>com.bariscagriyuce.yucemaccleaner</string>
  <key>CFBundleExecutable</key><string>$EXE</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>CFBundleVersion</key><string>$BUILD</string>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleLocalizations</key>
  <array><string>en</string><string>tr</string><string>pt-BR</string></array>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>LSApplicationCategoryType</key><string>public.app-category.utilities</string>
  <key>NSHumanReadableCopyright</key><string>© 2026 Baris Yuce</string>
  <key>NSAppleEventsUsageDescription</key><string>Access to Finder is needed to empty the Trash.</string>
</dict>
</plist>
PLIST

# Localized Info.plist strings (also lets macOS offer a per-app language choice).
write_lproj() {
  mkdir -p "$APP/Contents/Resources/$1.lproj"
  cat > "$APP/Contents/Resources/$1.lproj/InfoPlist.strings" <<STRINGS
"CFBundleDisplayName" = "YUCE Mac Cleaner";
"NSAppleEventsUsageDescription" = "$2";
STRINGS
}
write_lproj en    "Access to Finder is needed to empty the Trash."
write_lproj tr    "Çöp Kutusunu boşaltmak için Finder'a erişim gerekir."
write_lproj pt-BR "É necessário acesso ao Finder para esvaziar a Lixeira."

if [[ -n "$SIGN_ID" ]]; then
  codesign --force --timestamp --options runtime \
    --entitlements Resources/YUCEMacCleaner.entitlements \
    --sign "$SIGN_ID" "$APP"
  codesign --verify --strict --deep --verbose=1 "$APP"
else
  codesign --force --sign - "$APP" >/dev/null 2>&1 || true
fi
echo "Built: $(pwd)/$APP ($VERSION, build $BUILD)"

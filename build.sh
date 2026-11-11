#!/bin/zsh
# Builds "YUCE Mac Cleaner.app" from the Swift sources.
set -e
cd "$(dirname "$0")"

APP="YUCE Mac Cleaner.app"
EXE="YUCEMacCleaner"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

swiftc -O -parse-as-library -swift-version 5 \
  -target "$(uname -m)-apple-macos14.0" \
  Sources/*.swift -o "$APP/Contents/MacOS/$EXE"

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
  <key>CFBundleShortVersionString</key><string>1.1</string>
  <key>CFBundleVersion</key><string>2</string>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleLocalizations</key>
  <array><string>en</string><string>tr</string><string>pt-BR</string></array>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>NSHighResolutionCapable</key><true/>
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

codesign --force --sign - "$APP" >/dev/null 2>&1 || true
echo "Built: $(pwd)/$APP"

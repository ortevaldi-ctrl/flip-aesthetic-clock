#!/bin/zsh
set -euo pipefail
cd "${0:A:h}/.."
mkdir -p build/FLIP.app/Contents/MacOS build/FLIP.app/Contents/Resources build/ModuleCache Resources/FLIP.iconset
# Rebuild representations from the approved icon; do not regenerate the former artwork.
for size in 16 32 128 256 512; do
  sips -z "$size" "$size" Resources/FLIP-master-1024.png --out "Resources/FLIP.iconset/icon_${size}x${size}.png" >/dev/null
  double=$((size * 2))
  sips -z "$double" "$double" Resources/FLIP-master-1024.png --out "Resources/FLIP.iconset/icon_${size}x${size}@2x.png" >/dev/null
done
python3 Scripts/PackIcon.py
# Build the application and its real WidgetKit extension together.
xcodebuild -quiet -project FLIP.xcodeproj -scheme FLIP-With-Widget -configuration Release \
  -destination 'platform=macOS,arch=arm64' -derivedDataPath "$PWD/build/MacRelease/DerivedData" \
  build CODE_SIGNING_ALLOWED=NO CONFIGURATION_BUILD_DIR="$PWD/build" > build/mac-release.log 2>&1
codesign --force --sign - --entitlements Sources/Widget/FLIPWidget.entitlements build/FLIP.app/Contents/PlugIns/FLIPWidgets.appex
codesign --force --sign - build/FLIP.app
codesign --verify --deep --strict build/FLIP.app
print 'Local ad hoc package built. This does not verify WidgetKit loading; use development signing in Xcode.'

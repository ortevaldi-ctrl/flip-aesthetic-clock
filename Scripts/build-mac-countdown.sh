#!/bin/zsh
set -euo pipefail
cd "${0:A:h}/.."
mkdir -p build/MacCountdownPreview
xcodebuild -quiet -project FLIP.xcodeproj -scheme FLIP -configuration Release \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath "$PWD/build/MacCountdownPreview/DerivedData" build \
  CODE_SIGNING_ALLOWED=NO CONFIGURATION_BUILD_DIR="$PWD/build/MacCountdownPreview" \
  > build/MacCountdownPreview/build.log 2>&1
codesign --force --sign - --entitlements Sources/Widget/FLIPWidget.entitlements build/MacCountdownPreview/FLIP.app/Contents/PlugIns/FLIPWidgets.appex
codesign --force --sign - build/MacCountdownPreview/FLIP.app
codesign --verify --deep --strict build/MacCountdownPreview/FLIP.app
print "Clock/countdown preview (WidgetKit loading requires development signing): $PWD/build/MacCountdownPreview/FLIP.app"

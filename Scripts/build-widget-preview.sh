#!/bin/zsh
set -euo pipefail
cd "${0:A:h}/.."
mode="${1:-unsigned}"
mkdir -p build/MacWidgetPreview build/WidgetVerification
case "$mode" in
  unsigned)
    xcodebuild -quiet -project FLIP.xcodeproj -scheme FLIP-With-Widget \
      -configuration Release -destination 'platform=macOS,arch=arm64' \
      -derivedDataPath "$PWD/build/MacWidgetPreview/DerivedData" build CODE_SIGNING_ALLOWED=NO \
      CONFIGURATION_BUILD_DIR="$PWD/build/MacWidgetPreview" > build/WidgetVerification/build-unsigned.log 2>&1
    print 'Compiled: build/MacWidgetPreview/FLIP.app (unsigned). Widget loading has NOT been verified.'
    ;;
  development)
    [[ -n "${FLIP_DEVELOPMENT_TEAM:-}" ]] || { print -u2 'Set FLIP_DEVELOPMENT_TEAM to the Personal Team identifier shown by Xcode.'; exit 2; }
    xcodebuild -quiet -project FLIP.xcodeproj -scheme FLIP-With-Widget \
      -configuration Debug -destination 'platform=macOS,arch=arm64' \
      -derivedDataPath "$PWD/build/MacWidgetDevelopment/DerivedData" build \
      CODE_SIGN_STYLE=Automatic CODE_SIGN_IDENTITY='Apple Development' DEVELOPMENT_TEAM="$FLIP_DEVELOPMENT_TEAM" \
      CONFIGURATION_BUILD_DIR="$PWD/build/MacWidgetDevelopment" > build/WidgetVerification/build-development.log 2>&1
    codesign --verify --deep --strict build/MacWidgetDevelopment/FLIP.app
    print 'Development-signed build: build/MacWidgetDevelopment/FLIP.app. Verify the widget in macOS before calling loading complete.'
    ;;
  *) print -u2 'Usage: Scripts/build-widget-preview.sh [unsigned|development]'; exit 2 ;;
esac

#!/bin/zsh
set -euo pipefail
cd "${0:A:h}/.."
platform="${1:-simulator}"
case "$platform" in
  simulator) sdk=iphonesimulator; config=Debug; output=iOSSimulator ;;
  device) sdk=iphoneos; config=Release; output=iOSDevice ;;
  *) print -u2 'Uso: Scripts/build-ios.sh [simulator|device]'; exit 2 ;;
esac
# Builds with the installed SDK without requiring a booted simulator.
# Device output is unsigned: install from Xcode with your Personal Team instead.
xcodebuild -project iOS/FLIP-iOS.xcodeproj -scheme FLIP-iOS \
  -configuration "$config" -sdk "$sdk" \
  -derivedDataPath "$PWD/build/iOSDerived/$output" build CODE_SIGNING_ALLOWED=NO \
  CONFIGURATION_BUILD_DIR="$PWD/build/$output"

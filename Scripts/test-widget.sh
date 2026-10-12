#!/bin/zsh
set -euo pipefail
cd "${0:A:h}/.."
mkdir -p build/WidgetVerification/ModuleCache
xcrun swiftc -parse-as-library -module-cache-path "$PWD/build/WidgetVerification/ModuleCache" \
  Sources/Widget/WidgetClockModel.swift Sources/Widget/WidgetLink.swift \
  Sources/Widget/WidgetClockView.swift Tests/WidgetChecks.swift -o build/WidgetVerification/WidgetChecks
build/WidgetVerification/WidgetChecks

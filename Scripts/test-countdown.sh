#!/bin/zsh
set -euo pipefail
cd "${0:A:h}/.."
mkdir -p build/CountdownVerification/ModuleCache
xcrun swiftc -parse-as-library -module-cache-path "$PWD/build/CountdownVerification/ModuleCache" \
  Sources/Shared/Countdown/CountdownState.swift Sources/Shared/Countdown/CountdownNotifications.swift \
  Sources/Shared/Countdown/CountdownController.swift Sources/Shared/Countdown/CountdownPersistence.swift Tests/CountdownChecks.swift \
  -o build/CountdownVerification/CountdownChecks
build/CountdownVerification/CountdownChecks

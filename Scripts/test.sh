#!/bin/zsh
set -euo pipefail
cd "${0:A:h}/.."
mkdir -p build/ModuleCache
xcrun swiftc -parse-as-library -module-cache-path "$PWD/build/ModuleCache" Sources/FLIP/TimeEngine.swift Tests/TimeEngineChecks.swift -o build/TimeEngineChecks
build/TimeEngineChecks

xcrun swiftc -parse-as-library -module-cache-path "$PWD/build/ModuleCache" Sources/FLIP/ControlsActivity.swift Sources/FLIP/Backgrounds.swift Sources/FLIP/CollectionBackground.swift Sources/FLIP/PremiumBackground.swift Tests/Phase4AChecks.swift -o build/Phase4AChecks
build/Phase4AChecks
xcrun swiftc -parse-as-library -module-cache-path "$PWD/build/ModuleCache" Sources/FLIP/FavoritesStore.swift Sources/FLIP/Backgrounds.swift Sources/FLIP/CollectionBackground.swift Sources/FLIP/PremiumBackground.swift Sources/FLIP/TimeEngine.swift Tests/Phase4BChecks.swift -o build/Phase4BChecks
build/Phase4BChecks

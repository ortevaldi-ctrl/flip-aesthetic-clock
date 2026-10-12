#!/bin/zsh
# Run manually from a normal Terminal after reviewing the built application.
set -euo pipefail
cd "${0:A:h}/.."
source_app="$PWD/build/FLIP.app"
target_app="/Applications/FLIP.app"
[[ -d "$source_app" ]] || { print -u2 'Compile first with ./Scripts/build.sh'; exit 1; }
[[ ! -e "$target_app" ]] || { print -u2 'FLIP already exists in Applications; nothing was overwritten.'; exit 2; }
codesign --verify --deep --strict "$source_app"
ditto "$source_app" "$target_app"
codesign --verify --deep --strict "$target_app"
print "Installed: $target_app"

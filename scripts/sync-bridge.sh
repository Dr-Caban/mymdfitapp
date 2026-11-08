#!/bin/sh
# Copies the JS bridge from the iOS source into the Android app's assets so both apps run the same script.
cd "$(dirname "$0")/.." && python3 - <<'PY'
s = open("MDfitApp/Sources/MDfit/Native/BridgeScript.swift").read()
js = s[s.index('#"""') + 4:s.rindex('"""#')]
open("android/app/src/main/assets/bridge.js", "w").write("// GENERATED from MDfitApp/Sources/MDfit/Native/BridgeScript.swift by scripts/sync-bridge.sh. Do not edit here.\n" + js)
print("bridge.js updated")
PY

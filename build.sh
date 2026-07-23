#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release

APP=dist/Nagara.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/Nagara "$APP/Contents/MacOS/Nagara"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
codesign --force -s - "$APP"
echo "built: $APP"

if [ "${1:-}" = "install" ]; then
    osascript -e 'quit app "Nagara"' 2>/dev/null || true
    sleep 1
    rm -rf /Applications/Nagara.app
    cp -R "$APP" /Applications/
    open /Applications/Nagara.app
    echo "installed: /Applications/Nagara.app"
fi

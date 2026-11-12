#!/bin/zsh
# Rebuilds Discrete for MFE and updates the installed app so the Dock/Spotlight version is current.
set -e
cd "$(dirname "$0")"
echo "Building..."
swiftc -parse-as-library Sources/main.swift -o DiscreteMFE_binary
pkill -x DiscreteMFE_binary 2>/dev/null || true
pkill -x DiscreteMFE 2>/dev/null || true
APPS=$(mdfind "kMDItemCFBundleIdentifier == 'com.sey.discretemfe'" | grep '\.app$' || true)
if [ -z "$APPS" ]; then
  mkdir -p ~/Applications
  APPS="$HOME/Applications/Discrete for MFE.app"
fi
echo "$APPS" | while IFS= read -r APP; do
  mkdir -p "$APP/Contents/MacOS"
  cp Info.plist "$APP/Contents/Info.plist"
  cp DiscreteMFE_binary "$APP/Contents/MacOS/DiscreteMFE"
  mkdir -p "$APP/Contents/Resources" && cp AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
  touch "$APP"
  /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP" 2>/dev/null || true
  codesign --force --deep -s - "$APP"
  echo "Updated: $APP"
  LAST="$APP"
done
killall Dock 2>/dev/null || true
sleep 1
open "$(echo "$APPS" | head -1)"
echo "Done."

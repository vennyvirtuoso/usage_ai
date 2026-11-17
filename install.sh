#!/bin/bash
set -e

echo "🪔 Installing Ghee-Khatam for macOS..."

./build.sh

APP_NAME="Ghee-Khatam"
TARGET_DIR="/Applications/${APP_NAME}.app"

echo "📂 Installing to ${TARGET_DIR}..."
rm -rf "${TARGET_DIR}"
cp -R "build/${APP_NAME}.app" /Applications/

echo "🔄 Registering app and Notification Center widget with LaunchServices..."
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "${TARGET_DIR}"
defaults delete com.apple.chronod extensionsPendingDescriptorRefetch 2>/dev/null || true
killall -9 chronod 2>/dev/null || true
killall -9 NotificationCenter 2>/dev/null || true
killall -9 GheeKhatam 2>/dev/null || true
killall -9 UsageAI 2>/dev/null || true

sleep 1
open -n -a "${TARGET_DIR}"

echo "🎉 Ghee-Khatam is now running in your menu bar!"
echo "👉 To add the widget: Click the Date/Time in the top-right -> Edit Widgets -> Select Ghee-Khatam -> Click +"

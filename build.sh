#!/bin/bash
set -e

echo "🪔 Building Ghee-Khatam & Notification Center Widget for macOS..."

mkdir -p /tmp/swift-tmp /tmp/swift-cache

APP_NAME="Ghee-Khatam"
BUILD_DIR="build"
APP_DIR="${BUILD_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
PLUGINS_DIR="${CONTENTS_DIR}/PlugIns"
WIDGET_APPEX="${PLUGINS_DIR}/GheeKhatamWidget.appex"
WIDGET_CONTENTS="${WIDGET_APPEX}/Contents"
WIDGET_MACOS="${WIDGET_CONTENTS}/MacOS"

rm -rf "${APP_DIR}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"
mkdir -p "${WIDGET_MACOS}"

# 1. Compile Main App
echo "📦 Compiling Ghee-Khatam Main App..."
MAIN_SWIFT_FILES=$(find Sources/UsageAI -name "*.swift" | sort)
TMPDIR=/tmp/swift-tmp swiftc \
    -module-cache-path /tmp/swift-cache \
    -O \
    -framework AppKit \
    -framework SwiftUI \
    -framework Combine \
    -framework WidgetKit \
    -framework AppIntents \
    ${MAIN_SWIFT_FILES} \
    -o "${MACOS_DIR}/GheeKhatam"

cp Resources/Info.plist "${CONTENTS_DIR}/Info.plist"

# 2. Compile Widget Extension for Notification Center
echo "🧩 Compiling GheeKhatamWidget.appex for Notification Center..."
WIDGET_SWIFT_FILES="Sources/UsageAIWidget/UsageAIWidget.swift Sources/UsageAI/Models/SharedQuotaSnapshot.swift"
TMPDIR=/tmp/swift-tmp swiftc \
    -module-cache-path /tmp/swift-cache \
    -O \
    -parse-as-library \
    -application-extension \
    -framework WidgetKit \
    -framework SwiftUI \
    -framework AppKit \
    -framework AppIntents \
    -Xlinker -e -Xlinker _NSExtensionMain \
    ${WIDGET_SWIFT_FILES} \
    -o "${WIDGET_MACOS}/GheeKhatamWidget"

cp Resources/Widget-Info.plist "${WIDGET_CONTENTS}/Info.plist"

# 3. Codesign Widget Extension and App
echo "🔏 Code signing extension and application bundle..."
SIGN_ID=$(security find-identity -v -p codesigning 2>/dev/null | grep "Apple Development" | head -n 1 | sed -E 's/.*"([^"]+)".*/\1/' || true)

if [ -n "${SIGN_ID}" ]; then
    echo "Using development signing identity: ${SIGN_ID}"
    codesign -s "${SIGN_ID}" -f --entitlements Resources/Widget.entitlements "${WIDGET_APPEX}"
    codesign -s "${SIGN_ID}" -f --entitlements Resources/App.entitlements "${APP_DIR}"
else
    echo "No Apple Development identity found, using ad-hoc signature..."
    codesign -s - -f --entitlements Resources/Widget.entitlements "${WIDGET_APPEX}"
    codesign -s - -f --entitlements Resources/App.entitlements "${APP_DIR}"
fi

echo "✅ Successfully built: ${APP_DIR} with Notification Center WidgetKit extension!"

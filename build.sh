#!/bin/bash
set -e

echo "🚀 Building Usage AI & Notification Center Widget for macOS..."

mkdir -p /tmp/swift-tmp /tmp/swift-cache

APP_NAME="Usage AI"
BUILD_DIR="build"
APP_DIR="${BUILD_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
PLUGINS_DIR="${CONTENTS_DIR}/PlugIns"
WIDGET_APPEX="${PLUGINS_DIR}/UsageAIWidget.appex"
WIDGET_CONTENTS="${WIDGET_APPEX}/Contents"
WIDGET_MACOS="${WIDGET_CONTENTS}/MacOS"

rm -rf "${APP_DIR}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"
mkdir -p "${WIDGET_MACOS}"

# 1. Compile Main App
echo "📦 Compiling Usage AI Main App..."
MAIN_SWIFT_FILES=$(find Sources/UsageAI -name "*.swift" | sort)
TMPDIR=/tmp/swift-tmp swiftc \
    -module-cache-path /tmp/swift-cache \
    -O \
    -framework AppKit \
    -framework SwiftUI \
    -framework Combine \
    -framework WidgetKit \
    ${MAIN_SWIFT_FILES} \
    -o "${MACOS_DIR}/UsageAI"

cp Resources/Info.plist "${CONTENTS_DIR}/Info.plist"

# 2. Compile Widget Extension for Notification Center
echo "🧩 Compiling UsageAIWidget.appex for Notification Center..."
WIDGET_SWIFT_FILES="Sources/UsageAIWidget/UsageAIWidget.swift Sources/UsageAI/Models/SharedQuotaSnapshot.swift"
TMPDIR=/tmp/swift-tmp swiftc \
    -module-cache-path /tmp/swift-cache \
    -O \
    -parse-as-library \
    -framework WidgetKit \
    -framework SwiftUI \
    -framework AppKit \
    ${WIDGET_SWIFT_FILES} \
    -o "${WIDGET_MACOS}/UsageAIWidget"

cp Resources/Widget-Info.plist "${WIDGET_CONTENTS}/Info.plist"

# 3. Codesign Widget Extension and App
echo "🔏 Code signing extension and application bundle..."
codesign -s - -f "${WIDGET_APPEX}" 2>/dev/null || true
codesign -s - -f "${APP_DIR}" 2>/dev/null || true

echo "✅ Successfully built: ${APP_DIR} with Notification Center WidgetKit extension!"

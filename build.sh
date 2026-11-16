#!/bin/bash
set -e

echo "🚀 Building Usage AI for macOS..."

mkdir -p /tmp/swift-tmp /tmp/swift-cache

APP_NAME="Usage AI"
BUILD_DIR="build"
APP_DIR="${BUILD_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

rm -rf "${APP_DIR}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# Collect all swift files
SWIFT_FILES=$(find Sources/UsageAI -name "*.swift" | sort)

echo "📦 Compiling Swift sources..."
TMPDIR=/tmp/swift-tmp swiftc \
    -module-cache-path /tmp/swift-cache \
    -O \
    -framework AppKit \
    -framework SwiftUI \
    -framework Combine \
    ${SWIFT_FILES} \
    -o "${MACOS_DIR}/UsageAI"

# Copy Info.plist
cp Resources/Info.plist "${CONTENTS_DIR}/Info.plist"

echo "✅ Successfully built: ${APP_DIR}"

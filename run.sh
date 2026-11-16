#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo "🔄 Terminating any previous running instance of Usage AI..."
pkill -9 -f "Usage AI.app" 2>/dev/null || true
pkill -9 -f "UsageAI" 2>/dev/null || true
sleep 1

./build.sh

echo "✨ Installing to /Applications..."
rm -rf "/Applications/Usage AI.app" 2>/dev/null || true
cp -R "build/Usage AI.app" "/Applications/" 2>/dev/null || true

echo "🚀 Launching fresh Usage AI..."
open "/Applications/Usage AI.app" 2>/dev/null || open "build/Usage AI.app"
echo "✅ Usage AI is now live in your macOS menu bar!"

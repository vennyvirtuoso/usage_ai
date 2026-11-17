#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo "🔄 Terminating any previous running instance of Ghee-Khatam..."
pkill -9 -f "Ghee-Khatam.app" 2>/dev/null || true
pkill -9 -f "GheeKhatam" 2>/dev/null || true
pkill -9 -f "Usage AI.app" 2>/dev/null || true
pkill -9 -f "UsageAI" 2>/dev/null || true
sleep 1

./build.sh

echo "✨ Installing to /Applications..."
rm -rf "/Applications/Usage AI.app" 2>/dev/null || true
rm -rf "/Applications/Ghee-Khatam.app" 2>/dev/null || true
cp -R "build/Ghee-Khatam.app" "/Applications/" 2>/dev/null || true

echo "🚀 Launching fresh Ghee-Khatam..."
open "/Applications/Ghee-Khatam.app" 2>/dev/null || open "build/Ghee-Khatam.app"
echo "✅ Ghee-Khatam is now live in your macOS menu bar!"

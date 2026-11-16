#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

if [ ! -d "build/Usage AI.app" ]; then
    ./build.sh
fi

echo "✨ Launching Usage AI (Menu Bar & Desktop Widget)..."
open "build/Usage AI.app"
echo "Usage AI is running in your macOS menu bar!"

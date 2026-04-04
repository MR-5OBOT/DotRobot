#!/usr/bin/env bash

set -euo pipefail

SCREENSHOT_DIR="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
TIMESTAMP="$(date '+%Y-%m-%d_%H-%M-%S')"
FILE_PATH="${SCREENSHOT_DIR}/Screenshot_${TIMESTAMP}.png"

mkdir -p "$SCREENSHOT_DIR"

if ! command -v grimblast >/dev/null 2>&1; then
    exit 1
fi

if ! command -v slurp >/dev/null 2>&1; then
    exit 1
fi

grimblast --notify copysave area "$FILE_PATH"

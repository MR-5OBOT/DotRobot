#!/usr/bin/env bash
set -euo pipefail

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
source "$(dirname "$0")/seed-quickshell-settings.sh"

DEFAULT_SETTINGS="$tmp/default.json"
SETTINGS_FILE="$tmp/settings.json"
LOG_FILE="$tmp/test.log"
printf default >"$DEFAULT_SETTINGS"
main
printf personal >"$SETTINGS_FILE"
printf changed >"$DEFAULT_SETTINGS"
main

[[ $(<"$SETTINGS_FILE") == personal ]]
echo "Quickshell settings seed test passed"

#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
check_dir="$(mktemp -d)"
trap 'rm -rf -- "$check_dir"' EXIT
cp -r "$repo_dir/dotfiles/.config/quickshell/rishot/src/." "$check_dir/"
mv "$check_dir/shell.qml" "$check_dir/Rishot.qml"
cp "$repo_dir/tests/rishot-startup.qml" "$check_dir/shell.qml"
# Use Wayland's backend, but keep every capture overlay hidden throughout the test.
dbus-run-session -- env -u HYPRLAND_INSTANCE_SIGNATURE \
    QT_QPA_PLATFORM=wayland QT_NO_XDG_DESKTOP_PORTAL=1 \
    RISHOT_CAPTURE=screencopy RISHOT_SAVEDIR="$check_dir/shots" \
    timeout 15s qs -p "$check_dir" --no-color 2>&1 | tee "$check_dir/test.log"
grep -qF "Rishot capture-before-focus and pointer-input checks passed." "$check_dir/test.log"

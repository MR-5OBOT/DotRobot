#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
check_dir="$(mktemp -d)"
trap 'rm -rf -- "$check_dir"' EXIT
# Quickshell confines imports to its config root, so stage the real components together.
cp -r "$repo_dir/dotfiles/.config/quickshell/island" "$check_dir/island"
cp -r "$repo_dir/dotfiles/.config/quickshell/widgets" "$check_dir/widgets"
cp "$repo_dir/tests/notifications.qml" "$check_dir/shell.qml"
dbus-run-session -- env -u WAYLAND_DISPLAY QT_QPA_PLATFORM=offscreen \
    XDG_STATE_HOME="$check_dir/state" timeout 20s qs -p "$check_dir" --no-color 2>&1 | tee "$check_dir/test.log"
grep -qF "Notification grouping, stack layout, expansion, criticals and clearing checks passed." "$check_dir/test.log"

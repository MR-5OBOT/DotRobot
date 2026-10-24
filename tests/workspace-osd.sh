#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
check_dir="$(mktemp -d)"
trap 'rm -rf -- "$check_dir"' EXIT
cp -r "$repo_dir/dotfiles/.config/quickshell/island" "$check_dir/island"
cp -r "$repo_dir/dotfiles/.config/quickshell/widgets" "$check_dir/widgets"
cp "$repo_dir/tests/workspace-osd.qml" "$check_dir/shell.qml"
# Render the real panel layout with transparent, click-through test overlays.
dbus-run-session -- env -u HYPRLAND_INSTANCE_SIGNATURE \
    QT_QPA_PLATFORM=wayland QT_NO_XDG_DESKTOP_PORTAL=1 XDG_STATE_HOME="$check_dir/state" \
    timeout 15s qs -p "$check_dir" --no-color 2>&1 | tee "$check_dir/test.log"
grep -qF "Workspace OSD placement, orientation, timeout and volume checks passed." "$check_dir/test.log"

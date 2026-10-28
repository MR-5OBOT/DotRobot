#!/usr/bin/env bash
set -euo pipefail
repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/run" "$tmp/state" "$tmp/cache"
chmod 700 "$tmp/run"
cp -r "$repo/dotfiles/.config/quickshell/island" "$tmp/island"
cp -r "$repo/dotfiles/.config/quickshell/widgets" "$tmp/widgets"
ln -s /usr/bin/bash "$tmp/bin/bash"
printf '#!/bin/sh\nprintf "%%s\\n" "$@" >> "$TEST_NOTIFY"\n' > "$tmp/bin/notify-send"
chmod +x "$tmp/bin/notify-send"
touch "$tmp/video.mp4" "$tmp/other.mp4"
printf 'existing wallpaper state\n' > "$tmp/state/island-wallpaper-map"
cat > "$tmp/shell.qml" <<'QML'
import QtQuick
import Quickshell
import "island/Singletons" as Island
ShellRoot {
    Timer {
        interval: 100
        running: true
        onTriggered: {
            Island.Walls.apply(Quickshell.env("TEST_VIDEO"), "eDP-1");
            Island.Walls.apply(Quickshell.env("TEST_VIDEO"), "HDMI-A-1");
            Island.Walls.apply(Quickshell.env("TEST_VIDEO2"), "all");
        }
    }
    Timer { interval: 1500; running: true; onTriggered: Qt.quit() }
}
QML
env -u WAYLAND_DISPLAY -u DBUS_SESSION_BUS_ADDRESS QT_QPA_PLATFORM=offscreen XDG_RUNTIME_DIR="$tmp/run" XDG_STATE_HOME="$tmp/state" XDG_CACHE_HOME="$tmp/cache" PATH="$tmp/bin" TEST_VIDEO="$tmp/video.mp4" TEST_VIDEO2="$tmp/other.mp4" TEST_NOTIFY="$tmp/notice" /usr/bin/timeout 8s /usr/bin/qs -p "$tmp" --no-color > "$tmp/log" 2>&1
if [[ ! -f "$tmp/notice" ]] || [[ "$(grep -cx 'Video wallpaper unavailable' "$tmp/notice")" -ne 2 ]]; then
    cat "$tmp/log" >&2
    exit 1
fi
grep -qx 'existing wallpaper state' "$tmp/state/island-wallpaper-map"
printf 'The picker reports unavailable video playback once per file and preserves saved wallpaper state.\n'

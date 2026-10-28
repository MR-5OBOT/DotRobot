#!/usr/bin/env bash
set -euo pipefail
repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/state/island"
printf '#!/bin/sh\nprintf "%%s\\n" '\''[{"name":"eDP-1"},{"name":"HDMI-A-1"}]'\''\n' > "$tmp/bin/hyprctl"
printf '#!/bin/sh\nexit 1\n' > "$tmp/bin/pgrep"
printf '#!/bin/sh\nexit 0\n' > "$tmp/bin/sleep"
printf '#!/bin/sh\nprintf "%%s\\n" "$@" > "$TEST_ARGS"\n' > "$tmp/bin/setsid"
chmod +x "$tmp/bin/"*
touch "$tmp/video with spaces.mp4"
printf 'eDP-1\t%s\nHDMI-A-1\t%s\n' "$tmp/video with spaces.mp4" "$tmp/video with spaces.mp4" > "$tmp/state/island-wallpaper-map"
printf '{"wallpaperFit":"fit"}\n' > "$tmp/state/island/flags.json"
PATH="$tmp/bin:$PATH" XDG_STATE_HOME="$tmp/state" TEST_ARGS="$tmp/args" bash "$repo/dotfiles/.config/quickshell/island/scripts/wallpaper.sh" restore
python3 - "$tmp" <<'PY'
import pathlib, sys
p = pathlib.Path(sys.argv[1])
args = (p / 'args').read_text().splitlines()
assert args[0:3] == ['-f', 'mpvpaper', '-p'], args
assert args[-2:] == ['*', str(p / 'video with spaces.mp4')], args
assert 'panscan=0' in args[-3], args
PY
printf 'Wallpaper restore uses the saved video, fit and shared output.\n'

# Missing video support must not overwrite the saved wallpaper map.
cp "$tmp/state/island-wallpaper-map" "$tmp/map-before"
set +e
PATH="$tmp/bin" XDG_STATE_HOME="$tmp/state" /usr/bin/bash "$repo/dotfiles/.config/quickshell/island/scripts/wallpaper.sh" set "$tmp/video with spaces.mp4" > "$tmp/out" 2>&1
status=$?
set -e
[[ $status -eq 69 ]] || { cat "$tmp/out" >&2; exit 1; }
grep -q 'Video wallpapers are unavailable' "$tmp/out"
cmp "$tmp/map-before" "$tmp/state/island-wallpaper-map"
printf 'A missing video player is reported before saved wallpaper state changes.\n'

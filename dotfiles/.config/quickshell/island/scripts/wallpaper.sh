#!/usr/bin/env bash
# wallpaper.sh set <file> [output|all] — paint a wallpaper through awww and
# regenerate the island palette from it.
set -euo pipefail

FIT=crop # awww --resize: fill the screen, cropping the overflow
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/island-wallpaper"
MAP="${XDG_STATE_HOME:-$HOME/.local/state}/island-wallpaper-map"
STILL="${XDG_STATE_HOME:-$HOME/.local/state}/island-wallpaper-still.png"
WLOG="${XDG_STATE_HOME:-$HOME/.local/state}/island/wallcolors.log"
DEFAULT_WALL="$HOME/Pictures/wallpapers/mr5obot-prpl.jpg"

# The only place awww-daemon is started (login runs `restore`), so autostart and
# this script never race. A launch gets 3 s to answer; up to 5 launches, in case
# the first is slow or dies at login.
ensure_daemon() {
    local attempt
    awww query >/dev/null 2>&1 && return 0
    for attempt in 1 2 3 4 5; do
        awww-daemon >/dev/null 2>&1 &
        for _ in $(seq 1 15); do
            awww query >/dev/null 2>&1 && return 0
            sleep 0.2
        done
    done
    return 1
}

outputs() {
    hyprctl monitors -j 2>/dev/null | jq -r '.[].name'
}

focused_output() {
    hyprctl monitors -j 2>/dev/null | jq -r '[.[] | select(.focused)] | first.name // empty'
}

map_get() {
    awk -F'\t' -v o="$1" '$1 == o { print $2; exit }' "$MAP" 2>/dev/null || true
}

map_put() {
    mkdir -p "$(dirname "$MAP")"
    { awk -F'\t' -v o="$1" '$1 != o' "$MAP" 2>/dev/null || true; printf '%s\t%s\n' "$1" "$2"; } > "$MAP.tmp"
    mv "$MAP.tmp" "$MAP"
}

map_put_all() {
    local o
    mkdir -p "$(dirname "$MAP")"
    : > "$MAP.tmp"
    for o in $(outputs); do
        printf '%s\t%s\n' "$o" "$1" >> "$MAP.tmp"
    done
    mv "$MAP.tmp" "$MAP"
}

make_still() {
    ffmpeg -y -loglevel error -i "$1" -frames:v 1 -f image2 -c:v png "$2.tmp" && mv "$2.tmp" "$2"
}

# Animated gifs wave in over their own first frame, then swap to the live gif
# with no transition: the frames are identical, so the restart never reads as a
# flicker at the end of the wave.
apply_visual() {
    local pic="$1" out="${2:-}" show="$1" st
    local -a oflag=()
    [ -n "$out" ] && oflag=(--outputs "$out")
    case "${pic##*.}" in
        [Gg][Ii][Ff])
            st="$STILL"
            [ -n "$out" ] && st="${STILL%.png}-$out.png"
            make_still "$pic" "$st" && show="$st"
            ;;
    esac
    awww img ${oflag[@]+"${oflag[@]}"} "$show" \
        --resize "$FIT" \
        --transition-type wave \
        --transition-angle 30 \
        --transition-wave "60,30" \
        --transition-fps 60 \
        --transition-step 90
    if [ "$show" != "$pic" ]; then
        sleep 0.9
        awww img ${oflag[@]+"${oflag[@]}"} "$pic" --resize "$FIT" --transition-type none
    fi
}

# The palette follows the focused monitor: whatever hangs there drives wallcolors,
# the global state file and the global still, so the accent and the picker's
# current marker stay coherent with what the user looks at.
palette_update() {
    local focused pic
    focused=$(focused_output)
    pic=""
    [ -n "$focused" ] && pic=$(map_get "$focused")
    [ -n "$pic" ] || pic=$(cat "$STATE" 2>/dev/null || true)
    [ -n "$pic" ] && [ -f "$pic" ] || return 0
    mkdir -p "$(dirname "$STATE")"
    printf '%s\n' "$pic" > "$STATE"
    mkdir -p "$(dirname "$WLOG")"
    python3 "$(dirname "$0")/wallcolors.py" "$pic" >>"$WLOG" 2>&1 || true
}

# Hyprland 0.57 leaves a wallpaper layer that mapped under a fullscreen window at
# alpha 0. hypr/lua_configs/wallpaper.lua runs `heal` once its screen is uncovered.
# heal acts only while Hyprland really holds an awww layer at alpha 0, so a fixed
# Hyprland never pays for a restart.
stuck() {
    hyprctl layers -j | jq -e --arg ns "$1" '[.[].levels[][] | select(.namespace == $ns and .alpha == 0)] | length > 0' >/dev/null
}

# Restart awww: the new daemon maps fresh surfaces and restores its own last images.
# Screens blink once; waiting for the old one to exit keeps the new one off its socket.
if [ "${1:-}" = "heal" ]; then
    if stuck awww-daemon; then
        pkill -x awww-daemon && timeout 3 pidwait -x awww-daemon || true
        ensure_daemon || exit 1
    fi
    exit 0
fi

# Login: start awww, which brings back its own last images; only a first login has nothing to restore.
if [ "${1:-}" = "restore" ]; then
    ensure_daemon || exit 1
    [ -s "$MAP" ] && exit 0
    for _ in {1..20}; do
        [ -n "$(outputs || true)" ] && exec bash "$0" set "$DEFAULT_WALL"
        sleep 0.25
    done
    exit 1
fi

[ "${1:-}" = "set" ] || { echo "usage: wallpaper.sh set <file> [output|all]" >&2; exit 2; }
pic="${2:-}"
[ -f "$pic" ] || exit 1
target="${3:-}"
[ "$target" = "all" ] && target=""

ensure_daemon || exit 0

if [ -n "$target" ]; then
    map_put "$target" "$pic"
else
    map_put_all "$pic"
fi

apply_visual "$pic" "$target"
palette_update

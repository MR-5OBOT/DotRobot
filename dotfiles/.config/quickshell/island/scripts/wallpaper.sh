#!/usr/bin/env bash
# wallpaper.sh set <file> [output|all] — paint a wallpaper through awww and
# regenerate the island palette from it.
set -euo pipefail

flags_file="${XDG_STATE_HOME:-$HOME/.local/state}/island/flags.json"
FIT=$(jq -r '.wallpaperFit // "crop"' "$flags_file" 2>/dev/null || echo crop)
case "$FIT" in no|crop|fit|stretch) ;; *) FIT=crop ;; esac
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/island-wallpaper"
MAP="${XDG_STATE_HOME:-$HOME/.local/state}/island-wallpaper-map"
STILL="${XDG_STATE_HOME:-$HOME/.local/state}/island-wallpaper-still.png"
WLOG="${XDG_STATE_HOME:-$HOME/.local/state}/island/wallcolors.log"
DEFAULT_WALL="$HOME/Pictures/wallpapers/mr5obot-prpl.jpg"

ensure_daemon() {
    awww query >/dev/null 2>&1 && return 0
    local attempt i
    for attempt in 1 2 3 4 5; do
        awww-daemon >/dev/null 2>&1 &
        for i in $(seq 1 15); do
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
# the global state file and the global still, so the Settings dynamic re-run
# and the picker's current marker stay coherent with what the user looks at.
palette_update() {
    local pmode focused pic mh md ms
    focused=$(focused_output)
    pic=""
    [ -n "$focused" ] && pic=$(map_get "$focused")
    [ -n "$pic" ] || pic=$(cat "$STATE" 2>/dev/null || true)
    [ -n "$pic" ] && [ -f "$pic" ] || return 0
    mkdir -p "$(dirname "$STATE")"
    printf '%s\n' "$pic" > "$STATE"
    pmode=$(jq -r '.paletteMode // "static"' "$flags_file" 2>/dev/null || echo static)
    mkdir -p "$(dirname "$WLOG")"
    if [ "$pmode" = "manual" ]; then
        mh=$(jq -r '.manualHue // 30' "$flags_file" 2>/dev/null || echo 30)
        md=$(jq -r 'if .manualDark == false then "light" else "dark" end' "$flags_file" 2>/dev/null || echo dark)
        ms=$(jq -r '.manualSat // 0.5' "$flags_file" 2>/dev/null || echo 0.5)
        python3 "$(dirname "$0")/wallcolors.py" --hue "$mh" "$md" "$ms" >>"$WLOG" 2>&1 || true
    else
        python3 "$(dirname "$0")/wallcolors.py" "$pic" >>"$WLOG" 2>&1 || true
    fi
}

# Hyprland 0.57 leaves a wallpaper layer that mapped under a fullscreen window at
# alpha 0. hypr/lua_configs/wallpaper.lua runs `heal` once its screen is uncovered.
# heal acts only while Hyprland really holds an awww layer at alpha 0, so a fixed
# Hyprland never pays for a restart; `respawn` always restarts.
stuck() {
    hyprctl layers -j | jq -e --arg ns "$1" '[.[].levels[][] | select(.namespace == $ns and .alpha == 0)] | length > 0' >/dev/null
}

# Swap awww under a frozen copy so healthy screens never go blank: the stopped old
# daemon keeps its surfaces up while the new one restores its cache (~0.6s for a
# 3440px still) and maps above them, then the old one dies. SIGKILL only: a clean
# exit would unlink the socket the new daemon now owns.
respawn_stills() {
    local old want
    old=$(pgrep -x awww-daemon | tr '\n' ' ' || true)
    want=$(awww query 2>/dev/null | sort || true)
    if [ -n "$old" ]; then
        trap "kill -KILL $old 2>/dev/null" EXIT
        kill -STOP $old 2>/dev/null || true
        rm -f "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/$(basename "${WAYLAND_DISPLAY:-wayland-0}")-awww-daemon.sock"
    fi
    ensure_daemon || exit 1
    [ -n "$old" ] || return 0
    for _ in $(seq 1 100); do
        [ "$(awww query 2>/dev/null | sort)" = "$want" ] && break
        sleep 0.05
    done
    sleep 0.2 # let the restored frames reach the screen
    kill -KILL $old 2>/dev/null || true
    trap - EXIT
}

if [ "${1:-}" = "respawn" ] || [ "${1:-}" = "heal" ]; then
    if [ "$1" = respawn ] || stuck awww-daemon; then respawn_stills; fi
    exit 0
fi

# awww brings back its own last images; only a first login has nothing to restore.
if [ "${1:-}" = "restore" ]; then
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

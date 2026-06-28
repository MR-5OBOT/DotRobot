#!/usr/bin/env bash

set -euo pipefail

# capture -> edit in satty -> copy to clipboard
#   no arg : click a window OR drag an area (slurp seeded with window boxes)
#   menu   : rofi -> normal (window/area) or delay 5s (full screen)

boxes() {  # active-workspace window rectangles for slurp to snap onto
    local ws; ws=$(hyprctl activeworkspace -j | jq .id)
    hyprctl clients -j | jq -r ".[] | select(.workspace.id == $ws) | \"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])\""
}

args=()
case "${1:-}" in
    menu)
        case "$(printf 'normal\ndelay 5s' | rofi -dmenu -p screenshot -theme ~/.config/rofi/screenshot.rasi)" in
            normal)     args=(-g "$(slurp <<<"$(boxes)")") ;;
            'delay 5s') sleep 5 ;;   # ponytail: full screen; slurp can't survive a sleep
            *) exit 0 ;;             # dismissed
        esac
        ;;
    *) args=(-g "$(slurp <<<"$(boxes)")") ;;
esac

grim -t ppm "${args[@]}" - | satty --filename - --fullscreen --copy-command wl-copy --early-exit

#!/usr/bin/env bash
# Right-click on the bare wallpaper -> open the power menu.
#
# Opens the menu only when the cursor is NOT over a visible window and NOT
# over a bar/panel/popup layer surface (the wallpaper layer itself is ignored).
# Bound non-consuming in Hyprland, so right-click keeps working normally inside
# apps, on waybar, etc.

# If the menu is already open, a right-click anywhere dismisses it (Esc-like).
if pgrep -x rofi >/dev/null 2>&1; then
    pkill -x rofi
    exit 0
fi

read -r cx cy < <(hyprctl cursorpos -j | jq -r '"\(.x) \(.y)"')

# Workspaces currently shown (one per monitor) -> only these windows are visible.
vis_ws=$(hyprctl monitors -j | jq -c '[.[].activeWorkspace.id]')

# Is the cursor over a visible window?
over_win=$(hyprctl clients -j | jq --argjson x "$cx" --argjson y "$cy" --argjson ws "$vis_ws" '
  [ .[]
    | select(.mapped and (.hidden | not))
    | select(.workspace.id as $w | $ws | index($w))
    | select($x >= .at[0] and $x < (.at[0] + .size[0])
         and $y >= .at[1] and $y < (.at[1] + .size[1])) ] | length')

# Is the cursor over a bar/panel/popup layer? (skip background level + wallpaper tools)
over_layer=$(hyprctl layers -j | jq --argjson x "$cx" --argjson y "$cy" '
  [ to_entries[]
    | .value.levels | to_entries[]
    | select(.key != "0")
    | .value[]
    | select((.namespace | test("hyprpaper|swaybg|swww|mpvpaper"; "i")) | not)
    | select($x >= .x and $x < (.x + .w) and $y >= .y and $y < (.y + .h)) ] | length')

if [ "$over_win" -eq 0 ] && [ "$over_layer" -eq 0 ]; then
    exec sh "$HOME/.config/hypr/scripts/rofi-powermenu.sh"
fi

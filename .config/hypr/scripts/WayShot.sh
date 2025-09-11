#!/usr/bin/env bash

# Dependencies: grim, slurp, wl-copy, dunstify, rofi, jq (for window mode)

# Variables
timestamp=$(date +%Y-%m-%d_%H-%M-%S)
screenshot_dir="$HOME/Pictures/Screenshots"
filename="Screenshot_${timestamp}.png"
filepath="${screenshot_dir}/${filename}"
notification_icon="/usr/share/icons/Papirus-Dark/symbolic/devices/camera-photo-symbolic.svg"
notification_id=701 # Using a different ID to avoid potential conflicts

# Ensure the screenshot directory exists
mkdir -p "$screenshot_dir"

# Notify the user about the screenshot status
notify() {
    local urgency="$1"
    local summary="$2"
    local body="$3"
    dunstify -u "$urgency" --replace="$notification_id" -i "$notification_icon" "$summary" "$body"
}

# Copy the image to the clipboard and notify
finalize_screenshot() {
    if [[ -e "$filepath" ]]; then
        cat "$filepath" | wl-copy
        notify low "Screenshot Saved" "$filename"
    else
        notify critical "Screenshot Failed" "Could not save the screenshot."
    fi
}

# Take a screenshot of a selected area
area_screenshot() {
    sleep 0.2 # Small delay for rofi to disappear
    local geometry=$(slurp -d -w 0 -c '#ff0000ff')
    if [[ -n "$geometry" ]]; then
        grim -g "$geometry" "$filepath" && finalize_screenshot
    else
        notify low "Selection Cancelled" "No area was selected."
    fi
}

# Take a fullscreen screenshot
fullscreen_screenshot() {
    grim "$filepath" && finalize_screenshot
}

# Display the Rofi menu for screenshot options
show_rofi_menu() {
    rofi -dmenu -config ~/.config/rofi/custom/Shoter.rasi -i -p " " -l 2 <<EOF
Area
Fullscreen
EOF
}

# Main execution
selected_option=$(show_rofi_menu)

# Small delay to ensure Rofi is closed before taking the screenshot
sleep 0.6

case "$selected_option" in
"Area") area_screenshot ;;
"Fullscreen") fullscreen_screenshot ;;
*) notify low "No Option Selected" "No screenshot mode was chosen." ;;
esac

exit 0

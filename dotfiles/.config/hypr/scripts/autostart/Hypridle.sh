#!/usr/bin/env bash
#  _   _                  _     _ _
# | | | |_   _ _ __  _ __(_) __| | | ___
# | |_| | | | | '_ \| '__| |/ _` | |/ _ \
# |  _  | |_| | |_) | |  | | (_| | |  __/
# |_| |_|\__, | .__/|_|  |_|\__,_|_|\___|
#        |___/|_|
#
# Description:
#   Toggle or check the status of hypridle.
#   - `status`: JSON output for Waybar
#   - `toggle`: Starts or stops hypridle

SERVICE="hypridle"

if [[ "$1" == "status" ]]; then
    sleep 0.5 # short delay to allow service state change
    if pgrep -x "$SERVICE" >/dev/null; then
        echo '{"text": "🟢 RUNNING", "class": "active", "tooltip": "Screen locking active\nClick to deactivate"}'
    else
        echo '{"text": "🔴 STOPPED", "class": "notactive", "tooltip": "Screen locking is OFF\nClick to activate"}'
    fi
    exit 0
fi

if [[ "$1" == "toggle" ]]; then
    if pgrep -x "$SERVICE" >/dev/null; then
        killall "$SERVICE" && notify-send "Hypridle stopped"
    else
        "$SERVICE" &
        disown && notify-send "Hypridle started"
    fi
    exit 0
fi

echo "Usage: $0 [status|toggle]"
exit 1

#!/usr/bin/env bash

# prayer time script for a reminder of the time of praying
CURRENT_TIME=$(date +"%I:%M %p")

# getting the prayer time for each prayer
if [[ "$CURRENT_TIME" == "08:26 PM"  ]]; then
        notify-send "Hey mr5obot, it's time for FAJR salat!"

    elif [[ "CURRENT_TIME" == "01:00 PM" ]]; then
        notify-send "Hey mr5obot, it's time for DOHR salat!"

    elif [[ "$CURRENT_TIME" == "05:20 PM" ]]; then
        notify-send "Hey mr5obot, it's time for ASR salat!"

    elif [[ "$CURRENT_TIME" == "07:20 PM" ]]; then
        notify-send "Hey mr5obot, it's time for MAGHREB salat!"

    elif [[ "$CURRENT_TIME" == "08:31 PM" ]]; then
        notify-send -u critical "Hey mr5obot, it's time for ICHAA salat!"

else
    echo "waitinfg fo prayer times"
fi

#!/usr//bin/env bash

FILE_NAME="screenshots-$(date +%F-%T).png"
FILE_PATH="${HOME}/Pictures/screenshots/${FILE_NAME}"

option2="Selected area"
option3="Fullscreen (delay 1 sec)"

options="$option2\n$option3"

choice=$(echo -e "$options" | rofi -dmenu -i -no-show-icons -l 2  -p "Take Screenshot")

case $choice in
    "$option2")
        grimblast --notify  copysave area "$FILE_PATH"
        ;;
    "$option3")
        sleep 1
        grimblast --notify  copysave output "$FILE_PATH"
        ;;
    *)
        echo "No valid option selected or cancelled."
        ;;
esac


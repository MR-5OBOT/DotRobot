#!/usr/bin/bash

# check all batteries and sent notifications if bateries get lower than 15% 
while true; do
    battery_info=$(acpi -b)
    IFS=$'\n'
    for line in $battery_info; do
        battery_level=$(echo $line | awk -F'[,:]' '{print $3}' | tr -dc '0-9')
        if [ "$battery_level" -lt 15 ]; then
            notify-send -i ~/.config/dunst/icons/low-battery.png "Battery is below 20%!" "Charging: ${battery_level}%"
            paplay ~/.config/dunst/sounds/battery-low.wav
        fi
    done
    sleep 120
 done

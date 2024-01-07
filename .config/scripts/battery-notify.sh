#!/bin/bash

# Function to check charger status
check_charger_status() {
 while true; do
    previous_status=$(acpi -a | grep -o 'on-line')
    sleep 1
    current_status=$(acpi -a | grep -o 'on-line')
    if [ "$current_status" != "$previous_status" ]; then
        if [ "$current_status" == "on-line" ]; then
            notify-send -i ~/.config/dunst/icons/battery-plugged-in.png "Charger Plugged In !"
            paplay ~/.config/dunst/sounds/device-added.oga
        else
            notify-send -i ~/.config/dunst/icons/battery-unplugged.png "Charger Unplugged !"
            paplay ~/.config/dunst/sounds/device-removed.oga
        fi
    fi
 done
}

# Function to check all batteries
check_all_batteries() {
 while true; do
    battery_info=$(acpi -b)
    IFS=$'\n'
    for line in $battery_info; do
        battery_level=$(echo $line | awk -F'[,:]' '{print $3}' | tr -dc '0-9')
        if [ "$battery_level" -lt 20 ]; then
            notify-send -i ~/.config/dunst/icons/low-battery.png "Battery is below 20%!" "Charging: ${battery_level}%"
            paplay ~/.config/dunst/sounds/battery-low.wav
        fi
    done
    sleep 60
 done
}

# Start the functions in the background
check_charger_status &
check_all_batteries &

# Wait for all background processes to finish
wait

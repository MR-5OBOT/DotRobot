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

# Function to check battery level
check_all_batteries() {
   while true; do

       battery_level_0=$(acpi -b | awk -F'[,:]' '/Battery 0/{print $3}' | tr -dc '0-9')
       battery_level_1=$(acpi -b | awk -F'[,:]' '/Battery 1/{print $3}' | tr -dc '0-9')

       if [ "${battery_level_0}" -lt 90 ]; then
           notify-send -i ~/.config/dunst/icons/low-battery.png "Battery 0 is below 20%!" "Charging: ${battery_level_0}%"
           paplay ~/.config/dunst/sounds/battery-low.wav
       fi

       if [ "${battery_level_1}" -lt 10 ]; then
           notify-send -i ~/.config/dunst/icons/low-battery.png "Battery 1 is below 10%!" "Charging: ${battery_level_1}%"
           paplay ~/.config/dunst/sounds/battery-low.wav
       fi
       sleep 60
   done
}

# Start the functions in the background
check_charger_status &
check_all_batteries &

# Wait for all background processes to finish
wait

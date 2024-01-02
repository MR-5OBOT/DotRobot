#!/bin/bash

# Function to check charger status
check_charger() {
   while true; do
       PREVIOUS=$(acpi -a | grep -o 'on-line')
       sleep 1
       CURRENT=$(acpi -a | grep -o 'on-line')
       if [ "$CURRENT" != "$PREVIOUS" ]; then
           if [ "$CURRENT" == "on-line" ]; then
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
check_battery() {
   while true; do

       battery_level_0=$(acpi -b | awk -F'[,:]' '/Battery 0/{print $3}' | tr -dc '0-9')
       battery_level_1=$(acpi -b | awk -F'[,:]' '/Battery 1/{print $3}' | tr -dc '0-9')

       if [ "${battery_level_0}" -lt 20 ]; then
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
check_charger &
check_battery &

# Wait for all background processes to finish
wait

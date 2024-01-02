#!/bin/bash

PREVIOUS=$(acpi -a | grep -o 'on-line')
battery_level_0=$(acpi -b | awk -F'[,:]' '/Battery 0/{print $3}' | tr -dc '0-9')

while true; do
 CURRENT=$(acpi -a | grep -o 'on-line')
 if [ "$CURRENT" != "$PREVIOUS" ]; then
 if [ "$CURRENT" == "on-line" ]; then
   paplay ~/.config/dunst/sounds/device-added.oga
   notify-send -i ~/.config/dunst/icons/battery-plugged-in.png "Charger Plugged In !"
 else
   paplay ~/.config/dunst/sounds/device-removed.oga
   notify-send -i ~/.config/dunst/icons/battery-unplugged.png "Charger Unplugged !"
 fi
  PREVIOUS=$CURRENT
 fi

sleep 6 

 if [[ "${battery_level_0}" -lt 90 ]]; then
   paplay ~/.config/dunst/sounds/battery-low.wav
   notify-send -i ~/.config/dunst/icons/low-battery.png "Battery 0 is below 20%!" "Charging: ${battery_level_0}%"
 fi

echo "PID of this script: $$"

done

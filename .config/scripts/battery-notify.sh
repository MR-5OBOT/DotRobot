#!/bin/bash

PREVIOUS=$(acpi -a | grep -o 'on-line')

while true; do
 CURRENT=$(acpi -a | grep -o 'on-line')
 battery_level_0=$(acpi -b | awk -F'[,:]' '/Battery 0/{print $3}' | tr -dc '0-9')
 battery_level_1=$(acpi -b | awk -F'[,:]' '/Battery 1/{print $3}' | tr -dc '0-9')

 if [ "$CURRENT" != "$PREVIOUS" ]; then
    if [ "$CURRENT" == "on-line" ]; then
      notify-send -i ~/.config/dunst/icons/battery-plugged-in.png "Charger Plugged In !"
    else
      notify-send -i ~/.config/dunst/icons/battery-unplugged.png "Charger Unplugged !"
    fi
    PREVIOUS=$CURRENT
 fi

 if (( battery_level_0 < 30 )); then
   notify-send -i ~/.config/dunst/icons/low-battery.png "Battery 0 is below 99%!" "Charging: ${battery_level_0}%"
 fi

 # if (( battery_level_1 < 30 )); then
   # notify-send -i ~/.config/dunst/icons/low-battery.png "Battery 1 is below 20%!" "Charging: ${battery_level_1}%"
 # fi

 sleep 20 # 20 seconds
done

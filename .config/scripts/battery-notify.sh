#!/bin/bash

PREVIOUS=$(acpi -a | grep -o 'on-line')

while true; do
 CURRENT=$(acpi -a | grep -o 'on-line')
 if [ "$CURRENT" != "$PREVIOUS" ]; then
    if [ "$CURRENT" == "on-line" ]; then
      notify-send -i ~/.config/dunst/icons/battery-plugged-in.png "Charger Plugged In !"
    else
      notify-send -i ~/.config/dunst/icons/battery-unplugged.png "Charger Unplugged !"
    fi
    PREVIOUS=$CURRENT
 fi
 sleep 1
done

while true
do
 battery_level_0=$(acpi -b | awk -F'[,:]' '/Battery 0/{print $3}' | tr -dc '0-9')

 if [ "${battery_level_0}" -lt 30 ]; then
 notify-send -i ~/.config/dunst/icons/low-battery.png "Battery 0 is below 30%!" "Charging: ${battery_level_0}%"
 fi

 sleep 90 # 300 seconds or 5 minutes
done


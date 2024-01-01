#!/bin/bash

PREVIOUS=$(acpi -a | grep -o 'on-line')

while true; do

 CURRENT=$(acpi -a | grep -o 'on-line')

 battery_level_0=$(acpi -b | awk -F'[,:]' '/Battery 0/{print $3}' | tr -dc '0-9')

 if [ "$CURRENT" != "$PREVIOUS" ]; then
   if [ "$CURRENT" == "on-line" ]; then
     paplay /usr/share/sounds/freedesktop/stereo/power-plug.oga
     notify-send -i ~/.config/dunst/icons/battery-plugged-in.png "Charger Plugged In !"
   else
     paplay /usr/share/sounds/freedesktop/stereo/power-unplug.oga
     notify-send -i ~/.config/dunst/icons/battery-unplugged.png "Charger Unplugged !"
   fi
   PREVIOUS=$CURRENT
 fi

 if (( battery_level_0 < 30 )); then
  paplay /usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga
  notify-send -i ~/.config/dunst/icons/low-battery.png "Battery 0 is below 30%!" "Charging: ${battery_level_0}%"
 fi

done

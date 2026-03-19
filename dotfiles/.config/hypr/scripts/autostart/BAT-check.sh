#!/usr/bin/bash

if command -v acpi; then
    echo "acpi is installed"
else
    echo "acpi is not installed"
fi

# infinite loop for the script to make it check the BAT0 every 5 minutes
while true; do

# get the battery levels
get_percentage=$(acpi -b | grep -oP "\d+%" | head -n 1 | tr -d "%")
bat0_percentage=$(acpi -b | head -n 1 )

if [[ "$get_percentage" -lt 10 ]]; then
    # send notification
    notify-send -u critical "⚠️ Low Battery" "$bat0_percentage - Plug in your charger!"
fi

# check the battery for every 5 minutes 
sleep 300

done

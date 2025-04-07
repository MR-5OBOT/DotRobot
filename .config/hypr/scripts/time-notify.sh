#!/usr/bin/env bash

# Get local time and New York time
local_time=$(date '+%a %b %e %l:%M %p')
new_york_time=$(TZ="America/New_York" date '+%a %b %e %l:%M %p')

# Send notification with both times
notify-send -t 4500 "Local Time: $local_time\nNew York Time: $new_york_time"

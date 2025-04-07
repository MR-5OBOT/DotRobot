#!/usr/bin/env bash

# Format: "Fri, Apr 5 12:34 PM"
local_time=$(date +"%a, %b %d %I:%M %p")

# Get New York time with the same format
new_york_time=$(TZ="America/New_York" date +"%a, %b %d %I:%M %p")

# Send notification with both times in separate lines
notify-send -t 10000 "Morocco: $local_time"
notify-send -t 10000 "New York: $new_york_time"

#!/bin/bash

# Set the RAM usage thresholds (can be multiple)
thresholds=70

# Loop continuously
while true; do

  # Get current RAM usage percentage
  usage=$(free -m | awk '/Mem:/{print int($3/$2 * 100)}')

  # Check for each threshold
  for threshold in "${thresholds[@]}"; do
    if [[ $usage -ge $threshold ]]; then
      # Send notification (customize)
      notify-send "High RAM usage!" "RAM usage is at $usage%. Please close some applications."

      # Additional actions (optional)
      # pkill -SIGRTTT $(ps -eo pid,rss | sort -nrk 2 | head -n 5 | awk '{print $1}')

      # Break out of the loop after first trigger
      break
    fi
  done

  # Sleep for a while before checking again
  sleep 200

done

# Optionally run the script in the background (detach from terminal)
# nohup bash ram_monitor.sh &> /dev/null &



#!/bin/bash

# Threshold for CPU usage
THRESHOLD=70

# Function to check CPU usage
check_cpu_usage() {
    # Get the current CPU usage percentage
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    echo "$CPU_USAGE"
}

# Main loop
while true; do
    # Get the current CPU usage
    CURRENT_USAGE=$(check_cpu_usage)

    # Check if the current usage exceeds the threshold
    if (( $(echo "$CURRENT_USAGE > $THRESHOLD" | bc -l) )); then
        echo "High CPU usage detected: ${CURRENT_USAGE}%. Running 'clipse -clear-images'."
        clipse -clear-images
    else
        echo "CPU usage is normal: ${CURRENT_USAGE}%."
    fi

    # Wait for a specified interval before checking again
    sleep 10  # Adjust the sleep duration as needed
done


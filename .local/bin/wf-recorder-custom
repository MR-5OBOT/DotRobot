#!/bin/bash

# Check if required tools are installed
if ! command -v wf-recorder &>/dev/null || ! command -v fzf &>/dev/null || ! command -v grim &>/dev/null || ! command -v slurp &>/dev/null || ! command -v hyprctl &>/dev/null; then
	echo "wf-recorder, fzf, grim, slurp, or hyprctl not found. Please install them first."
	exit 1
fi

# Function for mouse selection area recording
record_mouse_area() {
	output_file="${HOME}/Videos/wayland_recording_$(date +'%Y-%m-%d_%H-%M-%S').mkv"

	# Capture the selected area with slurp and return the geometry coordinates
	echo "Select a region to record with the mouse."
	selected_area=$(slurp) # Get geometry from slurp

	if [ $? -eq 0 ]; then
		echo "Recording the selected area to: $output_file"
		wf-recorder -g "$selected_area" -f "$output_file" & # Start recording the selected area
		record_pid=$!
		wait $record_pid
		echo "Recording stopped. File saved as: $output_file"
	else
		echo "Region selection failed. Aborting."
	fi
}

# Function to select a specific application window
record_app_window() {
	output_file="${HOME}/Videos/wayland_recording_$(date +'%Y-%m-%d_%H-%M-%S').mkv"

	# Get a list of all windows using hyprctl
	window_list=$(hyprctl clients -j | jq -r '.[] | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1]) \(.title)"')

	# Use fzf to let the user select a window
	selected_window=$(echo "$window_list" | fzf --prompt="Select Window to Record: ")

	if [ -z "$selected_window" ]; then
		echo "No window selected. Aborting."
		exit 1
	fi

	# Extract geometry from the selected window
	geometry=$(echo "$selected_window" | awk '{print $1","$2}')
	window_title=$(echo "$selected_window" | cut -d' ' -f3-)

	echo "Recording window: $window_title"
	wf-recorder -g "$geometry" -f "$output_file" & # Start recording the selected window
	record_pid=$!
	wait $record_pid
	echo "Recording stopped. File saved as: $output_file"
}

# Show the selection menu using fzf
chosen=$(echo -e "Mouse Selection\nApplication Window" | fzf --prompt="Select Recording Option: ")

# Handle the user's choice
case "$chosen" in
"Mouse Selection")
	record_mouse_area
	;;
"Application Window")
	record_app_window
	;;
*)
	echo "No valid option selected. Exiting."
	exit 1
	;;
esac

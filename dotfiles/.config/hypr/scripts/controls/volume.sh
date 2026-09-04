#!/bin/bash
## /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Scripts for volume controls for audio and mic

# Show the quickshell OSD island (icon + progress bar); it reads the level
# itself. No-op if qs is down.  $1 = volume | mic
osd() { qs ipc call osd "$1" >/dev/null 2>&1; }

# Get Volume
get_volume() {
	volume=$(pamixer --get-volume)
	if [[ "$volume" -eq "0" ]]; then
		echo "Muted"
	else
		echo "$volume%"
	fi
}

# Get icons
get_icon() {
	current=$(get_volume)
	if [[ "$current" == "Muted" ]]; then
		echo ""
	elif [[ "${current%\%}" -le 30 ]]; then
		echo ""
	elif [[ "${current%\%}" -le 60 ]]; then
		echo ""
	else
		echo ""
	fi
}

# Notify
notify_user() {
	osd volume
}

# Increase Volume
inc_volume() {
	if [ "$(pamixer --get-mute)" == "true" ]; then
		pamixer -u && notify_user
	fi
	pamixer -i 5 && notify_user
}

# Decrease Volume
dec_volume() {
	if [ "$(pamixer --get-mute)" == "true" ]; then
		pamixer -u && notify_user
	fi
	pamixer -d 5 && notify_user
}

# Toggle Mute
toggle_mute() {
	if [ "$(pamixer --get-mute)" == "false" ]; then
		pamixer -m && osd volume
	elif [ "$(pamixer --get-mute)" == "true" ]; then
		pamixer -u && osd volume
	fi
}

# Toggle Mic
toggle_mic() {
	if [ "$(pamixer --default-source --get-mute)" == "false" ]; then
		pamixer --default-source -m && osd mic
	elif [ "$(pamixer --default-source --get-mute)" == "true" ]; then
		pamixer --default-source -u && osd mic
	fi
}
# Get Mic Icon
get_mic_icon() {
	current=$(pamixer --default-source --get-volume)
	if [[ "$current" -eq "0" ]]; then
		echo ""
	else
		echo ""
	fi
}

# Get Microphone Volume
get_mic_volume() {
	volume=$(pamixer --default-source --get-volume)
	if [[ "$volume" -eq "0" ]]; then
		echo "Muted"
	else
		echo "$volume%"
	fi
}

# Notify for Microphone
notify_mic_user() {
	osd mic
}

# Increase MIC Volume
inc_mic_volume() {
	if [ "$(pamixer --default-source --get-mute)" == "true" ]; then
		pamixer --default-source -u && notify_mic_user
	fi
	pamixer --default-source -i 5 && notify_mic_user
}

# Decrease MIC Volume
dec_mic_volume() {
	if [ "$(pamixer --default-source --get-mute)" == "true" ]; then
		pamixer --default-source -u && notify_mic_user
	fi
	pamixer --default-source -d 5 && notify_mic_user
}

# Execute accordingly
if [[ "$1" == "--get" ]]; then
	get_volume
elif [[ "$1" == "--inc" ]]; then
	inc_volume
elif [[ "$1" == "--dec" ]]; then
	dec_volume
elif [[ "$1" == "--toggle" ]]; then
	toggle_mute
elif [[ "$1" == "--toggle-mic" ]]; then
	toggle_mic
elif [[ "$1" == "--get-icon" ]]; then
	get_icon
elif [[ "$1" == "--get-mic-icon" ]]; then
	get_mic_icon
elif [[ "$1" == "--mic-inc" ]]; then
	inc_mic_volume
elif [[ "$1" == "--mic-dec" ]]; then
	dec_mic_volume
else
	get_volume
fi

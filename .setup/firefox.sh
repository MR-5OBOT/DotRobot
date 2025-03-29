#!/usr/bin/env bash

set -eo pipefail

# Header
gum style --border normal --margin "1 2" --padding "1 2" --align center "   MR5OBOT   "

# Paths
source_dir="$HOME/repos/DotRobot/.firefox/firefox"
dest_dir="$HOME/.mozilla/firefox"

# Find default release directory
default_release_dir=$(find "$dest_dir" -maxdepth 1 -type d -name "*.default-release" -print -quit)

if [[ -z "$default_release_dir" ]]; then
	echo "Error: No default-release directory found in $dest_dir"
	exit 1
fi

# List and select theme
echo "Available Firefox themes:"
mapfile -t themes < <(find "$source_dir" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)

select theme in "${themes[@]}" "Quit"; do
	[[ "$theme" == "Quit" ]] && exit 0
	[[ -n "$theme" ]] && break
	echo "Invalid selection. Try again."
done

# Create symlinks
theme_dir="$source_dir/$theme"
for item in "chrome" "user.js"; do
	ln -sfn "$theme_dir/$item" "$default_release_dir/"
done

notify-send "Firefox Theme Applied" "$theme linked successfully"
echo "Success: $theme theme applied to $default_release_dir"

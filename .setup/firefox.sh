#!/usr/bin/env bash

set -eo pipefail

# Show header (optional gum dependency)
command -v gum &>/dev/null && gum style --border normal --margin "1 2" --padding "1 2" --align center "   MR5OBOT   " || echo ">> MR5OBOT Firefox Theme Setup"

# Paths
source_dir="$HOME/repos/DotRobot/firefox"
dest_dir="$HOME/.mozilla/firefox"

# Find default Firefox profile dir
default_release_dir=$(find "$dest_dir" -maxdepth 1 -type d -name "*.default-release" -print -quit)

if [[ -z "$default_release_dir" ]]; then
    echo "❌ Error: No default-release directory found in $dest_dir"
    exit 1
fi

# Fetch available themes
mapfile -t themes < <(find "$source_dir" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)

if [[ ${#themes[@]} -eq 0 ]]; then
    echo "❌ No themes found in $source_dir"
    exit 1
fi

# Theme selection (interactive)
echo "🎨 Available Firefox themes:"
select theme in "${themes[@]}" "Quit"; do
    [[ "$theme" == "Quit" ]] && exit 0
    [[ -n "$theme" && -d "$source_dir/$theme" ]] && break
    echo "⚠️ Invalid selection. Try again."
done

# Apply theme (create symlinks without backups)
theme_dir="$source_dir/$theme"
for item in "chrome" "user.js"; do
    target="$default_release_dir/$item"
    [[ -e "$target" || -L "$target" ]] && rm -rf "$target"
    ln -s "$theme_dir/$item" "$target"
done

# Success messages
notify-send "Firefox Theme Applied" "'$theme' linked successfully"
echo "✅ Success: '$theme' theme applied to $default_release_dir"

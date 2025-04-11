#!/usr/bin/env bash
set -eo pipefail

# Header
command -v gum &>/dev/null && gum style --border normal --margin "1 2" --padding "1 2" --align center "MR5OBOT Fonts Setup" || echo "== MR5OBOT Fonts Setup =="

# Check for --no-confirm flag
confirm=true
for arg in "$@"; do
	[[ "$arg" == "--no-confirm" ]] && confirm=false
done

# Confirm if not --no-confirm
if $confirm; then
	gum confirm "Do you want to install and apply custom fonts?" || {
		echo "❌ Exiting script."
		exit 1
	}
fi

# 1. Install Pacman fonts
echo "📦 Installing fonts via pacman..."
sudo pacman -S --needed --noconfirm \
	ttf-iosevkaterm-nerd \
	ttf-font-awesome \
	ttf-daddytime-mono-nerd

# 2. Link local custom fonts
font_source_dir="$HOME/repos/DotRobot/.extra/.home/.fonts"
font_dest_dir="$HOME/.fonts"

mkdir -p "$font_dest_dir"

echo "🔗 Linking custom fonts to $font_dest_dir..."
found_any=false
for font_dir in "$font_source_dir"/*; do
	if [[ -d "$font_dir" ]]; then
		ln -sfn "$font_dir" "$font_dest_dir/$(basename "$font_dir")"
		echo "✅ Linked: $(basename "$font_dir")"
		found_any=true
	fi
done

if ! $found_any; then
	echo "⚠️ No custom font directories found in $font_source_dir"
fi

# 3. Refresh font cache
echo "🔄 Refreshing font cache..."
fc-cache -fv "$font_dest_dir"

# 4. Notify
command -v notify-send &>/dev/null && notify-send "Fonts Installed" "Custom fonts linked and font cache updated."

echo "🎉 Fonts setup complete!"

#!/usr/bin/env bash
set -e

gum style --border normal --margin "1 2" --padding "1 2" --align center "MR5OBOT dotfiles setup"

# Confirm setup
gum confirm "Proceed with dotfiles setup?" || {
	echo "Setup cancelled."
	exit 1
}

# Ensure correct repository structure
Dotfiles="$HOME/repos/DotRobot"
configs="$Dotfiles/.config"
fonts="$Dotfiles/.extra/.home/.fonts"

[[ -d "$Dotfiles" && -d "$configs" ]] || {
	echo "Error: DotRobot repo or .config missing."
	exit 1
}

# Safe linking function
safe_link() {
	mkdir -p "$(dirname "$2")"
	[[ -e "$2" ]] && rm -rf "$2"
	ln -sf "$1" "$2"
}

# Link .config files
echo "Linking .config files..."
for item in "$configs"/*; do safe_link "$item" "$HOME/.config/$(basename "$item")"; done

# Link shell config and scripts
echo "Linking shell config and scripts..."
safe_link "$Dotfiles/.zshrc" "$HOME/.zshrc"
mkdir -p "$HOME/.local/bin"
for script in "$Dotfiles/.local/bin"/*; do safe_link "$script" "$HOME/.local/bin/$(basename "$script")"; done

# Link wallpapers
safe_link "$Dotfiles/wallpapers" "$HOME/Pictures/wallpapers"

# Link post-checkout file
safe_link "$Dotfiles/.git/hooks/post-checkout" "$HOME/repos/DotRobot/.git/hooks/post-checkout"

# Link custom fonts
if [[ -d "$fonts" ]]; then
	echo "Linking custom fonts..."
	safe_link "$fonts" "$HOME/.fonts"
	fc-cache -fv
else
	echo "No custom fonts found."
fi

echo "Dotfiles setup complete!"
command -v notify-send &>/dev/null && notify-send "Dotfiles linked successfully!" "Enjoy @MR5OBOT"

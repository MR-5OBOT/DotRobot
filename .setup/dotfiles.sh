#!/usr/bin/env bash
set -euo pipefail

# Config
Dotfiles="$HOME/repos/DotRobot"
configs="$Dotfiles/.config"
confirm=true

# Args
for arg in "$@"; do
	case "$arg" in
	--no-confirm) confirm=false ;;
	esac
done

# Confirm setup
if "$confirm"; then
	command -v gum &>/dev/null && gum confirm "Proceed with dotfiles setup?" || {
		echo "Setup cancelled."
		exit 1
	}
fi

# Check paths
[[ -d "$Dotfiles" && -d "$configs" ]] || {
	echo "Error: DotRobot repo or .config missing."
	exit 1
}

# Safe symlink without backup
safe_link() {
	mkdir -p "$(dirname "$2")"
	[[ -e "$2" || -L "$2" ]] && rm -rf "$2"
	ln -sf "$1" "$2"
}

echo "[*] Linking .config files..."
for item in "$configs"/*; do
	safe_link "$item" "$HOME/.config/$(basename "$item")"
done

echo "[*] Linking shell configs..."
if [[ -f "$Dotfiles/.zshrc" ]]; then
	safe_link "$Dotfiles/.zshrc" "$HOME/.zshrc"
fi
if [[ -f "$Dotfiles/.bashrc" ]]; then
	safe_link "$Dotfiles/.bashrc" "$HOME/.bashrc"
fi

echo "[*] Linking local scripts..."
if [[ -d "$Dotfiles/.local/bin" ]]; then
	mkdir -p "$HOME/.local/bin"
	for script in "$Dotfiles/.local/bin"/*; do
		safe_link "$script" "$HOME/.local/bin/$(basename "$script")"
	done
fi

echo "[*] Linking wallpapers..."
safe_link "$Dotfiles/wallpapers" "$HOME/Pictures/wallpapers"

echo "[*] Linking git hook..."
safe_link "$Dotfiles/.git/hooks/post-checkout" "$Dotfiles/.git/hooks/post-checkout"

echo "✅ Dotfiles setup complete!"
command -v notify-send &>/dev/null && notify-send "Dotfiles linked successfully!" "Enjoy @MR5OBOT"
=======
#!/bin/bash
# Function to check if a directory exists and print a warning if not
check_dir() {
  if [ ! -d "$1" ]; then
    echo "Warning: Directory $1 does not exist!"
    echo ""
  fi
}

# Check the directories
check_dir "/home/mr5obot/.config"
check_dir "/home/mr5obot/.local/bin"
check_dir "/home/mr5obot/Pictures"
check_dir "/home/mr5obot"

# Create symlinks only if directories exist
if [ -d "/home/mr5obot/.config" ]; then
  ln -sf /home/mr5obot/repos/DotRobot/.config/* /home/mr5obot/.config/
  echo "Symlink created for .config files"
else
  echo "Skipping symlink creation for .config files"
fi

if [ -d "/home/mr5obot/.local" ]; then
  ln -sf /home/mr5obot/repos/DotRobot/.local/bin/ /home/mr5obot/.local/
  echo "Symlink created for .local/bin"
else
  echo "Skipping symlink creation for .local/bin"
fi

if [ -d "/home/mr5obot/Pictures" ]; then
  ln -sf /home/mr5obot/repos/DotRobot/wallpapers /home/mr5obot/Pictures/
  echo "Symlink created for wallpapers"
else
  echo "Skipping symlink creation for wallpapers"
fi

if [ -d "/home/mr5obot" ]; then
  ln -sf /home/mr5obot/repos/DotRobot/.zshrc /home/mr5obot/
  echo "Symlink created for .zshrc"
else
  echo "Skipping symlink creation for .zshrc"
fi


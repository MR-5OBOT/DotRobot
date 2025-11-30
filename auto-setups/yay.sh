#!/usr/bin/env bash
set -eo pipefail

# Header
gum style --border normal --margin "1 2" --padding "1 2" --align center "MR5OBOT yay setup"

# Colors
GREEN='\033[92m'
NONE='\033[0m'

# Check if yay is already installed
if command -v yay &>/dev/null; then
	echo ":: yay is already installed!"
else
	echo -e "${GREEN}"
	figlet "yay"
	echo -e "${NONE}"
	echo ":: yay is not installed. Installing yay from AUR..."

	# Clone yay-git and install
	git clone https://aur.archlinux.org/yay-git.git ~/yay-git
	cd ~/yay-git
	makepkg -si --noconfirm
	cd ~
	rm -rf ~/yay-git

	echo ":: yay has been installed successfully."
	notify-send "yay installed" "AUR helper is ready to use 🚀"
fi

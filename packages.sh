#!/usr/bin/env bash

echo "Updating system..."
sudo pacman -Syu --noconfirm || {
	echo "Update failed."
	exit 1
}

run_script() {
	echo "Running $1..."
	bash "$1" || {
		echo "Error: $1 failed."
		exit 1
	}
}

echo "Starting Hyprland setup (installing packages)"
gum confirm "Proceed with installation?" || {
	echo "Setup cancelled."
	exit 1
}

scripts=(
	".install/general-packages.sh"
	".install/hyprland-pkgs.sh"
	".install/custom-pkgs.sh"
)

for script in "${scripts[@]}"; do
	run_script "$script"
done

echo "Setup complete. Enjoy your system!"

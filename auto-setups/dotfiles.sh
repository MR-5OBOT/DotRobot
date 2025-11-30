#!/bin/bash
set -e  # Exit on error

# === BASE PATH ===
DOTFILES="$HOME/repos/DotRobot"

# === COLORS ===
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RESET="\033[0m"

# === FUNCTIONS ===
log() { echo -e "${YELLOW}[*]${RESET} $1"; }

link() {
  local src="$1"
  local dest="$2"

  mkdir -p "$(dirname "$dest")"  # Ensure parent directory exists
  ln -sfn "$src" "$dest"
  echo -e "${GREEN}[+]${RESET} Linked: $dest → $src"
}

# === LINK EVERYTHING UNDER .config ===
log "Linking .config files and folders..."
find "$DOTFILES/.config" -mindepth 1 -maxdepth 1 | while read -r item; do
  name="$(basename "$item")"
  link "$item" "$HOME/.config/$name"
done

# === LINK OTHER FILES/DIRS ===
log "Linking other dotfiles..."
link "$DOTFILES/.local/bin" "$HOME/.local/bin"
link "$DOTFILES/.local/share/applications" "$HOME/.local/share/"
link "$DOTFILES/wallpapers" "$HOME/Pictures/wallpapers"
link "$DOTFILES/.zshrc" "$HOME/.zshrc"

echo -e "\n${GREEN}All dotfiles linked successfully!${RESET}"

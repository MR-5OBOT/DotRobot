#!/bin/bash

# Base path
DOTFILES="$HOME/repos/DotRobot"

# Function to safely symlink (force overwrite)
link() {
  local src="$1"
  local dest="$2"

  ln -sfn "$src" "$dest"
  echo "Linked $dest -> $src"
}

# .config subdirectories (safer than linking everything at once)
for dir in "$DOTFILES/.config"/*; do
  [ -d "$dir" ] || continue
  link "$dir" "$HOME/.config/$(basename "$dir")"
done

# Other links
link "$DOTFILES/.local/bin" "$HOME/.local/bin"
link "$DOTFILES/wallpapers" "$HOME/Pictures/wallpapers"
link "$DOTFILES/.zshrc" "$HOME/.zshrc"

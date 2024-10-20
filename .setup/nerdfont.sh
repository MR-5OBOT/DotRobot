#!/usr/bin/env bash

# MR5OBOT Header
gum style --border normal --margin "1 2" --padding "1 2" --align center "MR5OBOT nerdfonts setup" 

# Set the path to the dotfiles repository
DOTFILES_PATH=~/MR-5OBOT/DotRoboT

# Destination directories
DESTINATIONS=("~/.config" "~/")

# Function to find the Firefox profile directory
find_firefox_profile() {
  local profile=$(find ~/.mozilla/firefox/ -maxdepth 1 -type d -name "*default-release")
  if [[ -z "$profile" ]]; then
    echo "Profile variable is empty"
  else
    echo "Firefox Profile is located"
    DESTINATIONS+=("$profile")
  fi
}

# Function to check if a file is a symlink
is_symlink() {
  if [[ -e $1 && -h $1 ]]; then
    return 0
  else
    return 1
  fi
}

# Function to update a file
update_file() {
  local file=$1
  local dest=$2
  if [[ -e $dest/$file ]]; then
    if is_symlink "$dest/$file"; then
      echo "Replacing symlink: $dest/$file"
      ln -sf $DOTFILES_PATH/$file $dest/$file
    fi
  fi
}

# Main loop
echo "Updating dotfiles..."
for file in "$DOTFILES_PATH"/*; do
  file=${file##*/} # Remove directory part of the path
  if [[ -e $DOTFILES_PATH/$file ]]; then
    echo "Processing file: $file"
    for dest in "${DESTINATIONS[@]}"; do
      update_file "$file" "$dest"
    done
  fi
done

# Find the Firefox profile directory
find_firefox_profile

echo "Dotfiles updated."


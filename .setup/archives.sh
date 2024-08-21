#!/usr/bin/env bash

# MR5OBOT Header
gum style --border normal --margin "1 2" --padding "1 2" --align center "MR5OBOT Archives Setup"

# Define source and destination directories
SOURCE_DIR="$HOME/repos/DotRoboT/.home/"
DEST_DIR="$HOME"

# Define the directories to copy
DIRS_TO_COPY=(".themes" ".icons" ".fonts")

# Ask for confirmation
read -r -p "Copy directories? ${DIRS_TO_COPY[*]} ? (y/n): " CONFIRMATION

# Check if confirmation is valid
if [[ $CONFIRMATION != "y" && $CONFIRMATION != "n" ]]; then
    echo "Invalid confirmation. Please enter 'y' or 'n'."
    exit 1
fi

# Copy the directories
for dir in "${DIRS_TO_COPY[@]}"; do
    if [[ -d "$SOURCE_DIR/$dir" ]]; then
        cp -r "$SOURCE_DIR/$dir" "$DEST_DIR"
        echo "Copied $dir to $DEST_DIR"
    else
        echo "Error: Directory '$dir' does not exist in $SOURCE_DIR"
    fi
done

echo "Directory copying complete."

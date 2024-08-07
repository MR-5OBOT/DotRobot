#!/usr/bin/env bash

# MR5OBOT Header
gum style --border normal --margin "1 2" --padding "1 2" --align center "MR5OBOT Archives Setup" 

# Define source and destination directories
SOURCE_DIR="$HOME/repos/DotRoboT/.extra/archives"
DEST_DIR="$HOME"

# Ask for confirmation
read -r -p "Copy directories? .icons, .themes, .fonts ? (y/n): " CONFIRMATION

# Check if confirmation is valid
if [[ $CONFIRMATION != "y" && $CONFIRMATION != "n" ]]; then
    echo "Invalid confirmation. Please enter 'y' or 'n'."
    exit 1
fi

# Iterate over directories in the source directory
for dir in $(find "$SOURCE_DIR" -type d -not -path "$SOURCE_DIR"); do
    DIR_NAME=$(basename "$dir")
    echo "Copying: $DIR_NAME"
    if [ -d "$DEST_DIR/$DIR_NAME" ]; then
        read -p "Destination directory already contains files with the same name. Overwrite? (y/n) " OVERWRITE_CONFIRMATION
        if [[ $OVERWRITE_CONFIRMATION != "y" ]]; then
            echo "Copying cancelled."
            exit 0
        fi
    fi
    cp -r "$dir" "$DEST_DIR/$DIR_NAME" && echo "Copied: $DIR_NAME"
done

echo "Directory copying complete."

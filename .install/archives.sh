#!/usr/bin/env bash

# MR5OBOT Header
gum style --border normal --margin "1 2" --padding "1 2" --align center "MR5OBOT Scripts for Managing Your Dotfiles and Configurations"
gum style --border normal --margin "1 2" --padding "1 2" --align center "Archives Setup"

# Define source and destination directories
SOURCE_DIR="$HOME/repos/DotRoboT/.extra/archives/"
DEST_DIR="$HOME/"

# Ask for confirmation
echo "Copy directories? .icons, .themes, .fonts ? (y/n)"
read -r CONFIRMATION

# Check if confirmation is valid
if [[ $CONFIRMATION != "y" && $CONFIRMATION != "n" ]]; then
    echo "Invalid confirmation. Please enter 'y' or 'n'."
    exit 1
fi

    for dir in $SOU; do
        if [ -d "$dir" ]; then
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
        fi
    done
    echo "Directory copying complete."
else
    echo "Directory copying cancelled."
fi

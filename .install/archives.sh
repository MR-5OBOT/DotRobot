#!/usr/bin/env bash

# Define colors
RED='\033[91m'
GREEN='\033[92m'
NONE='\033[0m']

# Define the source and destination directories
SOURCE_DIR=~/repos/DotRoboT/.extra/archives/
DEST_DIR=$HOME/

# Define the directories to link
DIRECTORIES=(".icons" ".themes" ".fonts")

# Function to link directories
link_directories() {
    local dir=$1
    local source_path="$SOURCE_DIR/$dir"
    local dest_path="$DEST_DIR/$dir"

    # Check if the directory exists
    if [ -d "$source_path" ]; then
        # Prompt to link the directory
        read -p "Link directory $dir? (y/n): " -n 1 -r
        echo    # (optional) move to a new line
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Link the directory
            ln -sf "$source_path" "$dest_path"
            echo -e "${GREEN}Linked $dir...${NONE}"
        else
            echo -e "${RED}Skipping link for $dir${NONE}"
        fi
    else
        echo -e "${RED}Error: Directory $dir not found${NONE}"
        exit 1
    fi
}

# Link each directory
for dir in "${DIRECTORIES[@]}"; do
    link_directories "$dir"
done

echo -e "${GREEN}Setup complete${NONE}"


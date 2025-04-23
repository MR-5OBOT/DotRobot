#!/usr/bin/env bash

# The name of the rclone remote for Google Drive
REMOTE_NAME="gdrive"

export RCLONE_CONFIG_PASS=ys

# The directory in Google Drive where you want to store the PDFs
GDRIVE_DIR="Digital-life/Latex_Projects/"

# Specify the main directory containing subdirectories
MAIN_DIR="$HOME/repos/Dev-Lab/latex-projects/"

# List all directories within the main directory
echo "Select the directory containing PDF files:"
directories=($(find "$MAIN_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;))

# Prompt the user to select a directory
PS3="Select a directory: "
select dir in "${directories[@]}"; do
    case $dir in
        *)
            LOCAL_DIR="$MAIN_DIR/$dir"
            break
            ;;
    esac
done

# Copy any new or modified PDF files from the selected local directory to Google Drive, excluding .git directories
rclone sync "$LOCAL_DIR" "$REMOTE_NAME:/$GDRIVE_DIR" --filter "+ *.pdf" --filter "- *" --filter "- .git/**"

# Check if the synchronization completed successfully
if [[ $? -eq 0 ]]; then
    echo "Files sync completed successfully"
else
    echo "Script failed"
fi

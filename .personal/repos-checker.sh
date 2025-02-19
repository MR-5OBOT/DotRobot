#!/bin/bash

# Define the root directory containing all the git repos
REPOS_DIR="/path/to/your/repos/directory" # Replace with your actual directory path

# Find and check each git repository for uncommitted changes
changes_found=0
for repo in "$REPOS_DIR"/*/.git; do
	repo_path=$(dirname "$repo")
	cd "$repo_path"
	if ! git diff-index --quiet HEAD --; then
		changes_found=1
		echo "Changes detected in $repo_path:"
		git status --porcelain
	fi
	cd - >/dev/null
done

# Send a desktop notification if changes were found
if [ $changes_found -eq 1 ]; then
	notify-send "Uncommitted Changes Detected" "Check your repositories."
fi

echo "Finished checking all repositories."

# To run this script every hour, you can use cron. Open your crontab file by running crontab -e in the terminal.
# Add the following line to schedule the script to run every hour:
# 0 * * * * /path/to/your/script/check_git_repos.sh
# This line tells cron to execute the script at the beginning of every hour.

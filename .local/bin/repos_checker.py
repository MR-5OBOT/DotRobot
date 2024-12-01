#!/usr/bin/env python3

import os
import subprocess
from datetime import datetime, timedelta


def notify_hyprland(title, message):
    """Send a notification in Hyprland using dunst."""
    subprocess.run(["notify-send", title, message])


def check_git_repos(base_dir):
    """Check Git repositories in the directory and its subdirectories."""
    unpushed_repos = []
    for root, dirs, files in os.walk(base_dir):
        if ".git" in dirs:
            git_dir = os.path.join(root, ".git")
            try:
                # Get the last commit timestamp
                commit_time = subprocess.check_output(["git", "log", "-1", "--format=%ct"], cwd=root).strip()

                # Check for unpushed commits
                unpushed = subprocess.check_output(
                    ["git", "log", "@{u}.."], cwd=root, stderr=subprocess.DEVNULL
                ).strip()

                # Convert timestamp to datetime
                last_commit_time = datetime.fromtimestamp(int(commit_time))
                time_diff = datetime.now() - last_commit_time

                if unpushed and time_diff > timedelta(hours=8):
                    unpushed_repos.append((root, last_commit_time))
            except subprocess.CalledProcessError:
                # Skip repos without an upstream branch or inaccessible repos
                continue
    return unpushed_repos


if __name__ == "__main__":
    BASE_DIR = os.path.expanduser("~/repos")  # Replace with the base directory you want to monitor

    repos = check_git_repos(BASE_DIR)

    if repos:
        for repo, commit_time in repos:
            notify_hyprland(
                "Unpushed Changes Detected", f"Repo: {repo}\nLast Commit: {commit_time.strftime('%Y-%m-%d %H:%M:%S')}"
            )

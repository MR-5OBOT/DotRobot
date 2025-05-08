#!/bin/bash
# Function to check if a directory exists and print a warning if not
check_dir() {
  if [ ! -d "$1" ]; then
    echo "Warning: Directory $1 does not exist!"
    echo ""
  fi
}

# Check the directories
check_dir "/home/mr5obot/.config"
check_dir "/home/mr5obot/.local/bin"
check_dir "/home/mr5obot/Pictures"
check_dir "/home/mr5obot"
check_dir "/home/mr5obot/repos/DotRobot/.git/hooks"

# Create symlinks only if directories exist
if [ -d "/home/mr5obot/.config" ]; then
  ln -sf /home/mr5obot/repos/DotRobot/.config/* /home/mr5obot/.config/
  echo "Symlink created for .config files"
else
  echo "Skipping symlink creation for .config files"
fi

if [ -d "/home/mr5obot/.local" ]; then
  ln -sf /home/mr5obot/repos/DotRobot/.local/bin/ /home/mr5obot/.local/
  echo "Symlink created for .local/bin"
else
  echo "Skipping symlink creation for .local/bin"
fi

if [ -d "/home/mr5obot/Pictures" ]; then
  ln -sf /home/mr5obot/repos/DotRobot/wallpapers /home/mr5obot/Pictures/
  echo "Symlink created for wallpapers"
else
  echo "Skipping symlink creation for wallpapers"
fi

if [ -d "/home/mr5obot" ]; then
  ln -sf /home/mr5obot/repos/DotRobot/.zshrc /home/mr5obot/
  echo "Symlink created for .zshrc"
else
  echo "Skipping symlink creation for .zshrc"
fi

if [ -d "/home/mr5obot/repos/DotRobot/.git/hooks" ]; then
  ln -sf /home/mr5obot/repos/DotRobot/.setup/post-checkout /home/mr5obot/repos/DotRobot/.git/hooks/
  echo "Symlink created for Git post-checkout hook"
else
  echo "Skipping symlink creation for Git post-checkout hook"
fi


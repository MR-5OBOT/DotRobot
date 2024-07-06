#!/usr/bin/env bash
## /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# This is for polkits, it will start from top and will stop if the top is executed

Polkit_icon="$HOME/.config/dunst/icons/polkit.png"

# Polkit possible paths files to check
polkit=(
  "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"
  "/usr/lib/polkit-kde-authentication-agent-1"
  "/usr/lib/polkit-gnome-authentication-agent-1"
  "/usr/libexec/polkit-gnome-authentication-agent-1"
  "/usr/lib/x86_64-linux-gnu/libexec/polkit-kde-authentication-agent-1"
  "/usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1"
)

executed=false  # Flag to track if a file has been executed

# Loop through the list of files
for file in "${polkit[@]}"; do
  if [ -e "$file" ]; then
    echo "File $file found, executing command..."
    notify-send -e "Polkit File found, executing command..." -i "$Polkit_icon"
    exec "$file"  
    executed=true
    break
  fi
done

# If none of the files were found, you can add a fallback command here
if [ "$executed" == false ]; then
  echo "none of the specified files were found. install a polkit"
  notify-send -e "none of the Polkits files were found. install a polkit" -i "$Polkit_icon"
fi

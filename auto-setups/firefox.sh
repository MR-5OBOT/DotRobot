#!/usr/bin/env bash
set -euo pipefail

# Banner
if command -v gum &>/dev/null; then
  gum style --border normal --margin "1 2" --padding "1 2" --align center "   MR5OBOT   "
else
  echo ">> MR5OBOT Firefox Theme Setup"
fi

# Paths
src="$HOME/repos/DotRobot/firefox"
dest="$HOME/.mozilla/firefox"
profile=$(find "$dest" -maxdepth 1 -type d -name "*.default-release" -print -quit)

[[ -z "$profile" ]] && { echo "❌ No default-release profile found"; exit 1; }

# List themes
mapfile -t themes < <(find "$src" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
[[ ${#themes[@]} -eq 0 ]] && { echo "❌ No themes found in $src"; exit 1; }

# Pick theme
echo "🎨 Choose a theme:"
select t in "${themes[@]}" Quit; do
  [[ $t == Quit ]] && exit
  [[ -n $t && -d $src/$t ]] && theme=$t && break
  echo "⚠️ Invalid choice."
done

# Apply theme
for item in chrome user.js; do
  ln -sfn "$src/$theme/$item" "$profile/$item"
done

notify-send "Firefox Theme Applied" "'$theme' linked successfully"
echo "✅ Applied theme: $theme"

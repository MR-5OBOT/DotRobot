#!/bin/bash

# Helper script to install nerd-fonts
REPO="ryanoasis/nerd-fonts"

latest_release() {
  local repo=$1
  local result=$(curl --silent "https://api.github.com/repos/$repo/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')
  echo "$result"
}

echo "==> Fetching latest release version of $REPO"
version=$(latest_release $REPO)
echo "==> Latest version is: $version"

RED='\033[0;31m'

install_font() {
  local fontname=$1
  echo -e "==> Downloading font ${RED}$fontname${NC} ......"
  echo "==> https://github.com/$REPO/releases/download/$version/$fontname.zip"
  wget https://github.com/$REPO/releases/download/$version/$fontname.zip
  unzip $fontname.zip -d ~/.fonts/$font
  sudo rm $fontname.zip
  fc-cache -f
  echo "==> done!"
  echo "fc-cache -f done>>>"
}

# Ask the user for the name(s) of the font(s) they want to install
echo "Please enter the name of the font(s) you want to install, separated by space (e.g., Gohu FiraCode):"
read -ra FONTS

# Loop through each font name provided by the user and install
for font in "${FONTS[@]}"; do
    install_font "$font"
done

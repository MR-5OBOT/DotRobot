#!/bin/bash
# Rofi menu for Quick Edit / View of Settings (SUPER E)

## Variables ##
Configs="$HOME/.config"
bashrc="$HOME/.bashrc"

# Function to display the menu options
menu() {
  echo "1) view Hypr_cfg"
  echo "2) view Hypr_scripts"
  echo "3) view Startup_apps"
  echo "4) view kitty_cfg"
  echo "5) view Starship_cfg"
  echo "6) view .bashrc_cfg"
}

# Main function to handle the menu selection
main() {
    # Display the menu and get the user's choice
    choice=$(menu | rofi -dmenu -config ~/.config/rofi/cfgs_viewer.rasi -p "=>")
    
    # Handle the selected option
    case $choice in
        "1) view Hypr_cfg")
            kitty -e nvim "$Configs/hypr/configs"
            ;;
        "2) view Hypr_scripts")
            kitty -e nvim "$Configs/hypr/scripts"
            ;;
        "3) view Startup_apps")
            kitty -e nvim "$Configs/hypr/autostart.sh"
            ;;
        "4) view kitty_cfg")
            kitty -e nvim "$Configs/kitty/"
            ;;
        "5) view Starship_cfg")
            kitty -e nvim "$Configs/Starship.toml"
            ;;
        "6) view .bashrc_cfg")
            kitty -e nvim "$bashrc"
            ;;
        *)
            echo "Invalid selection"
            ;;
    esac
}

main

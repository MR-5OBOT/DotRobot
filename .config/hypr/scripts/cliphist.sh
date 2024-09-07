#!/usr/bin/env sh

#   ____ _ _       _     _     _    
#  / ___| (_)_ __ | |__ (_)___| |_  
# | |   | | | '_ \| '_ \| / __| __| 
# | |___| | | |_) | | | | \__ \ |_  
#  \____|_|_| .__/|_| |_|_|___/\__| 
#           |_|                     
#  
# by Stephan Raabe (2023) 
# ----------------------------------------------------- 

# Check for required commands
for cmd in cliphist rofi wl-copy; do
    command -v "$cmd" >/dev/null 2>&1 || { echo >&2 "Error: $cmd is not installed. Please install it."; exit 1; }
done

# Function to display the clipboard history
show_clipboard_history() {
    cliphist list | rofi -dmenu -replace -config ~/.config/rofi/custom/clipboard.rasi
}

# Main script logic
case "$1" in
    d) 
        # Delete selected clipboard entry
        selected_entry=$(show_clipboard_history)
        [ -n "$selected_entry" ] && cliphist delete "$selected_entry" || echo "No entry selected."
        ;;

    w) 
        # Wipe clipboard history
        if [ "$(echo -e "Clear\nCancel" | rofi -dmenu -config ~/.config/rofi/custom/clipboard.rasi)" = "Clear" ]; then
            cliphist wipe
        fi
        ;;

    *) 
        # Paste selected clipboard entry
        selected_entry=$(show_clipboard_history | cliphist decode)
        if [ -n "$selected_entry" ]; then
            echo "$selected_entry" | wl-copy
        else
            echo "No entry selected."
        fi
        ;;
esac

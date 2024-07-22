# Check and enable PipeWire
if ! systemctl --user is-active --quiet pipewire; then
    echo "PipeWire is not running. Enabling and starting PipeWire..."
    systemctl --user enable --now pipewire
    notify-send "PipeWire Enabled" "PipeWire has been enabled and started."
else
    echo "PipeWire is already running."
    notify-send "PipeWire Running" "PipeWire is already enabled and running."
fi

# Check and enable WirePlumber
if ! systemctl --user is-active --quiet wireplumber; then
    echo "WirePlumber is not running. Enabling and starting WirePlumber..."
    systemctl --user enable --now wireplumber
    notify-send "WirePlumber Enabled" "WirePlumber has been enabled and started."
else
    echo "WirePlumber is already running."
    notify-send "WirePlumber Running" "WirePlumber is already enabled and running."
fi



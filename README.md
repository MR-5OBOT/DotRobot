# DotRobot

Arch Linux dotfiles: Hyprland (Lua config), a Quickshell bar, kitty, zsh and tmux.

## New machine

1. Install Arch with a sudo user and a working network, then `sudo pacman -S git`.
2. Clone the repo and run the installer as your normal user:

   ```sh
   git clone https://github.com/MR-5OBOT/DotRobot.git ~/repos/DotRobot
   cd ~/repos/DotRobot && ./install.sh
   ```

   Every step asks Y/n and can be re-run later. Linking replaces whatever is
   already at each target, including `~/Pictures/wallpapers`, without a backup.
3. Reboot, pick **Hyprland (uwsm-managed)** at the login screen, then press
   Super+/ for the keybinds and Super+W for wallpapers.

To adjust for other hardware, edit the external monitor in
`dotfiles/.config/hypr/lua_configs/monitors.lua` and the keyboard ids in
`dotfiles/keyd/default.conf` (then run `scripts/setup-keyd.sh`).

## Extra scripts

Run these when needed; each one explains itself as it runs.

See the [practical keyboard workflow report](docs/keyboard-workflow.md) for the
installed terminal alternatives, Brovim selection and current session decisions.

| Script | What it does |
|---|---|
| `scripts/setup-mobile-broadband.sh` | Cellular modem and carrier APN, including the Dell DW5825e FCC unlock (also offered by the installer) |
| `sudo scripts/fix-hotspot.sh` | Starts the saved NetworkManager hotspot and opens UFW for it |
| `scripts/setup-browser-shortcuts.py` | Helium shortcuts for Brovim; close Helium first, `--dry-run` previews |
| `assets/presets/kdenlive-config/kdenlive-setup.sh` | Kdenlive theme and layouts |
| `scripts/switch-from-wpa_supplicant-to-iwd.sh` | Switches the Wi-Fi backend to iwd; `revert` undoes it |
| `sudo bash scripts/setup-grub-theme.sh` | Obsidian GRUB theme for the UKI + Windows setup; preview with `scripts/preview-grub-theme.sh` |

#!/usr/bin/env bash
# Set up greetd + tuigreet, disabling whatever login manager is
# currently active (SDDM, GDM, LightDM, ...).
# tuigreet auto-lists /usr/share/wayland-sessions at login.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

require_arch
[[ $EUID -eq 0 ]] && die "Run as your normal user; the script sudo's when it needs root."

# display-manager.service is a symlink to the active DM's unit, whatever it is.
disable_active_dm() {
  local link="/etc/systemd/system/display-manager.service" dm
  if [[ ! -L "${link}" ]]; then
    log "No login manager currently active."
    return
  fi
  dm="$(basename "$(readlink "${link}")")"
  if [[ "${dm}" == "greetd.service" ]]; then
    log "greetd is already the active login manager."
    return
  fi
  log "Disabling current login manager: ${dm} (takes effect on reboot)"
  # no --now: stopping a live DM would kill the session this script runs in
  sudo systemctl disable "${dm}" 2>/dev/null || true
}

sudo pacman -S --needed --noconfirm greetd greetd-tuigreet

sudo tee /etc/greetd/config.toml >/dev/null <<'EOF'
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --remember --remember-session"
user = "greeter"
EOF
log "Wrote /etc/greetd/config.toml"

disable_active_dm
sudo systemctl enable greetd.service
log "Done. greetd + tuigreet enabled. Reboot to test."

#!/usr/bin/env bash
# Set up a login manager, ly or greetd + tuigreet, disabling whatever
# login manager is currently active (SDDM, GDM, LightDM, ...).
# Both auto-list /usr/share/wayland-sessions at login.
#
#   ./setup-login-manager.sh           # asks which one
#   ./setup-login-manager.sh ly
#   ./setup-login-manager.sh greetd
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

require_arch
[[ $EUID -eq 0 ]] && die "Run as your normal user; the script sudo's when it needs root."

# ly ships a template unit that does not alias display-manager.service, so the
# symlink check below cannot see it and it has to be disabled by name.
LY_UNIT="ly@tty1.service"

choose_dm() {
  local answer
  while true; do
    printf 'Login manager: [1] ly  [2] greetd + tuigreet (default 1): '
    read -r answer
    case "${answer:-1}" in
      1 | ly) DM=ly; return ;;
      2 | greetd) DM=greetd; return ;;
      *) warn "Answer with 1 or 2." ;;
    esac
  done
}

# display-manager.service is a symlink to the active DM's unit, whatever it is.
# no --now: stopping a live DM would kill the session this script runs in
disable_other_dms() {
  local keep="$1" link="/etc/systemd/system/display-manager.service" dm
  if [[ -L "${link}" ]]; then
    dm="$(basename "$(readlink "${link}")")"
    if [[ "${dm}" != "${keep}" ]]; then
      log "Disabling current login manager: ${dm} (takes effect on reboot)"
      # no 2>/dev/null || true: that hid sudo's auth prompt and swallowed its
      # failure, which would leave two DMs fighting over tty1
      sudo systemctl disable "${dm}"
    fi
  fi
  if [[ "${keep}" != "${LY_UNIT}" ]] && systemctl is-enabled --quiet "${LY_UNIT}" 2>/dev/null; then
    log "Disabling current login manager: ${LY_UNIT} (takes effect on reboot)"
    sudo systemctl disable "${LY_UNIT}"
  fi
}

setup_ly() {
  sudo pacman -S --needed --noconfirm ly
  disable_other_dms "${LY_UNIT}"
  sudo systemctl enable "${LY_UNIT}"
  # ly lists both Hyprland entries; only the uwsm one matches the greetd setup.
  # save = true (the default) remembers the pick, so this is a one-time choice.
  log "Done. ly enabled on tty1. Reboot, pick \"Hyprland (uwsm-managed)\" once; ly remembers it."
}

setup_greetd() {
  sudo pacman -S --needed --noconfirm greetd greetd-tuigreet

  sudo tee /etc/greetd/config.toml >/dev/null <<'EOF'
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --remember --remember-session --cmd 'uwsm start -e -D Hyprland hyprland.desktop'"
user = "greeter"
EOF
  log "Wrote /etc/greetd/config.toml"

  disable_other_dms "greetd.service"
  sudo systemctl enable greetd.service
  log "Done. greetd + tuigreet enabled. Reboot to test."
}

DM="${1:-}"
[[ -z "${DM}" ]] && choose_dm
case "${DM}" in
  ly) setup_ly ;;
  greetd) setup_greetd ;;
  *) die "Unknown login manager: ${DM} (use ly or greetd)" ;;
esac

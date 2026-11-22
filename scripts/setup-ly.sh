#!/usr/bin/env bash
# Set up ly as the login manager, disabling whatever login manager is currently
# active (SDDM, GDM, LightDM, ...). ly lists /usr/share/wayland-sessions at login.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

# ly ships a template unit that does not alias display-manager.service, so the
# symlink check below cannot see it and it is enabled by name.
LY_UNIT="ly@tty1.service"
DISABLED_DMS=()

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
      DISABLED_DMS+=("${dm}")
    fi
  fi
}

enable_dm() {
  local unit="$1" disabled

  if sudo systemctl enable "${unit}"; then
    return 0
  fi
  warn "Could not enable ${unit}; restoring the previous login manager."
  for disabled in "${DISABLED_DMS[@]}"; do
    sudo systemctl enable "${disabled}" || warn "Could not restore ${disabled}."
  done
  die "Login manager setup failed."
}

setup_ly() {
  pacman_install ly
  disable_other_dms "${LY_UNIT}"
  enable_dm "${LY_UNIT}"
  # ly lists both Hyprland entries; the uwsm one runs Hyprland as a systemd session.
  # save = true (the default) remembers the pick, so this is a one-time choice.
  log "Done. ly enabled on tty1. Reboot, pick \"Hyprland (uwsm-managed)\" once; ly remembers it."
}

main() {
  require_arch
  [[ $EUID -eq 0 ]] && die "Run as your normal user; the script sudo's when it needs root."
  setup_ly
}

main "$@"

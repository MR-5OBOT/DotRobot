#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

# Services needed by the desktop are automatic. Hardware/features the user may
# not use are opt-in so running the installer does not silently start them.
DEFAULT_UNITS=(NetworkManager.service power-profiles-daemon.service paccache.timer fstrim.timer)
OPTIONAL_UNITS=(bluetooth.service thermald.service)
# Session daemons as user units: uwsm starts them with the Hyprland session,
# systemd restarts them on a crash, and `journalctl --user -u <name>` has logs.
USER_UNITS=(cliphist.service hypridle.service hyprpolkitagent.service battery-notify.service)

enable_unit() {
  local unit="$1"
  if systemctl list-unit-files "${unit}" --no-legend 2>/dev/null | grep -q .; then
    sudo systemctl enable --now "${unit}"
    log "Enabled ${unit}"
  else
    log "Skipped ${unit} (not installed)"
  fi
}

main() {
  require_arch
  local unit answer
  for unit in "${DEFAULT_UNITS[@]}"; do
    enable_unit "${unit}"
  done
  for unit in "${USER_UNITS[@]}"; do
    if systemctl --user list-unit-files "${unit}" --no-legend 2>/dev/null | grep -q .; then
      systemctl --user enable "${unit}"
      log "Enabled user unit ${unit} (starts with the uwsm session)"
    else
      log "Skipped user unit ${unit} (not installed)"
    fi
  done
  for unit in "${OPTIONAL_UNITS[@]}"; do
    printf 'Enable optional %s? [y/N]: ' "${unit}"
    read -r answer || answer=""
    if [[ ${answer} =~ ^[Yy]$ ]]; then
      enable_unit "${unit}"
    else
      log "Skipped optional ${unit}"
    fi
  done
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  main "$@"
fi

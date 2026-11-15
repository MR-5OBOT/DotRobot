#!/usr/bin/env bash
set -euo pipefail

# setup-wifi-stability.sh
# Wi-Fi through iwd instead of wpa_supplicant, power saving off, and NetworkManager
# (not iwd) picking networks: fixes short drops.
# Undo: delete CONF_FILE, then `systemctl disable --now iwd`,
# `systemctl unmask wpa_supplicant` and restart NetworkManager.

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

CONF_FILE="/etc/NetworkManager/conf.d/99-wifi-stability.conf"

main() {
  [[ $EUID -eq 0 ]] || exec sudo "$0" "$@"

  local want
  want="$(cat <<'EOF'
[device]
wifi.backend=iwd
# NetworkManager drives autoconnect instead of iwd's signal ranking
wifi.iwd.autoconnect=false

# 0=default 1=ignore 2=disable 3=enable
[connection]
wifi.powersave=2
EOF
)"

  if [[ -f "${CONF_FILE}" ]] && [[ "$(cat "${CONF_FILE}")" == "${want}" ]]; then
    log "${CONF_FILE} already up to date"
    return 0
  fi

  pacman_install iwd
  mkdir -p "$(dirname "${CONF_FILE}")"
  printf '%s\n' "${want}" > "${CONF_FILE}"
  log "Wrote ${CONF_FILE}"
  # A running wpa_supplicant keeps fighting iwd over the Wi-Fi card until a reboot.
  systemctl mask --now wpa_supplicant
  systemctl enable --now iwd
  log "Restarting NetworkManager (Wi-Fi drops for a few seconds)..."
  systemctl restart NetworkManager
  log "Done. Check with: NetworkManager --print-config | grep -E 'backend|powersave|autoconnect'"
}

main "$@"

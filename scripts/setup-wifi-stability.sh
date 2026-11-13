#!/usr/bin/env bash
set -euo pipefail

# setup-wifi-stability.sh
# Turns off Wi-Fi power saving and lets NetworkManager (not iwd) pick networks.

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

CONF_FILE="/etc/NetworkManager/conf.d/99-wifi-stability.conf"

main() {
  [[ $EUID -eq 0 ]] || exec sudo "$0" "$@"

  local want
  want="$(cat <<'EOF'
# NetworkManager drives autoconnect instead of iwd's signal ranking
# (ignored when the backend is wpa_supplicant)
[device]
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

  mkdir -p "$(dirname "${CONF_FILE}")"
  printf '%s\n' "${want}" > "${CONF_FILE}"
  log "Wrote ${CONF_FILE}"
  log "Restarting NetworkManager (Wi-Fi drops for a few seconds)..."
  systemctl restart NetworkManager
  log "Done. Check with: NetworkManager --print-config | grep -E 'powersave|autoconnect'"
}

main "$@"

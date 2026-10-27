#!/usr/bin/env bash
set -euo pipefail

# switch-from-wpa_supplicant-to-iwd.sh
# Switches NetworkManager Wi-Fi backend from wpa_supplicant to iwd (or reverts back)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${SCRIPT_DIR}/lib.sh" ]]; then
  # shellcheck source=/dev/null
  source "${SCRIPT_DIR}/lib.sh"
else
  log() { printf '[*] %s\n' "$*"; }
  warn() { printf '[!] %s\n' "$*" >&2; }
  die() { warn "$*"; exit 1; }
fi

CONF_DIR="/etc/NetworkManager/conf.d"
CONF_FILE="${CONF_DIR}/wifi_backend.conf"

require_root() {
  if [[ $EUID -ne 0 ]]; then
    exec sudo "$0" "$@"
  fi
}

get_unit_active() {
  systemctl is-active "$1" 2>/dev/null || true
}

get_unit_enabled() {
  systemctl is-enabled "$1" 2>/dev/null || true
}

usage() {
  cat <<EOF
Usage: $(basename "$0") [iwd | revert | status]

Commands:
  iwd       Switch NetworkManager backend from wpa_supplicant to iwd (default)
  revert    Revert NetworkManager backend back to wpa_supplicant
  status    Show current Wi-Fi backend and service status
EOF
}

show_status() {
  printf '=== NetworkManager Wi-Fi Backend Status ===\n'
  if [[ -f "$CONF_FILE" ]] && grep -q "wifi.backend=iwd" "$CONF_FILE"; then
    printf 'Configured Backend : iwd (%s)\n' "$CONF_FILE"
  else
    printf 'Configured Backend : wpa_supplicant (default)\n'
  fi

  printf '\n=== Service States ===\n'
  printf '%-18s: %s (enabled: %s)\n' "iwd" \
    "$(get_unit_active iwd)" \
    "$(get_unit_enabled iwd)"
  printf '%-18s: %s (enabled: %s)\n' "wpa_supplicant" \
    "$(get_unit_active wpa_supplicant)" \
    "$(get_unit_enabled wpa_supplicant)"
  printf '%-18s: %s (enabled: %s)\n' "NetworkManager" \
    "$(get_unit_active NetworkManager)" \
    "$(get_unit_enabled NetworkManager)"

  printf '\n=== Device Status ===\n'
  nmcli device status 2>/dev/null || ip link
}

switch_to_iwd() {
  require_root
  log "Switching Wi-Fi backend from wpa_supplicant to iwd..."

  # Ensure iwd is installed
  if ! command -v iwd &>/dev/null; then
    log "iwd not found. Installing via pacman..."
    pacman -S --noconfirm --needed iwd
  fi

  # 1. Write NetworkManager drop-in config
  log "Writing ${CONF_FILE}..."
  mkdir -p "$CONF_DIR"
  cat << 'EOF' > "$CONF_FILE"
[device]
wifi.backend=iwd
EOF

  # 2. Stop and mask wpa_supplicant
  log "Stopping and masking wpa_supplicant..."
  systemctl stop wpa_supplicant 2>/dev/null || true
  systemctl mask wpa_supplicant

  # 3. Enable and start iwd
  log "Enabling and starting iwd..."
  systemctl unmask iwd 2>/dev/null || true
  systemctl enable --now iwd

  # 4. Restart NetworkManager
  log "Restarting NetworkManager..."
  systemctl restart NetworkManager

  log "Successfully switched Wi-Fi backend to iwd!"
}

revert_to_wpa_supplicant() {
  require_root
  log "Reverting Wi-Fi backend from iwd to wpa_supplicant..."

  # 1. Remove drop-in config
  if [[ -f "$CONF_FILE" ]]; then
    log "Removing ${CONF_FILE}..."
    rm -f "$CONF_FILE"
  fi

  # 2. Unmask and start wpa_supplicant
  log "Unmasking and enabling wpa_supplicant..."
  systemctl unmask wpa_supplicant
  systemctl enable --now wpa_supplicant

  # 3. Stop and disable iwd
  log "Stopping and disabling iwd..."
  systemctl stop iwd 2>/dev/null || true
  systemctl disable iwd 2>/dev/null || true

  # 4. Restart NetworkManager
  log "Restarting NetworkManager..."
  systemctl restart NetworkManager

  log "Successfully reverted Wi-Fi backend to wpa_supplicant!"
}

main() {
  local action="${1:-iwd}"

  case "$action" in
    iwd|--iwd)
      switch_to_iwd
      ;;
    revert|wpa|wpa_supplicant|--wpa|--revert)
      revert_to_wpa_supplicant
      ;;
    status|--status|-s)
      show_status
      ;;
    help|--help|-h)
      usage
      ;;
    *)
      warn "Unknown option: $action"
      usage
      exit 1
      ;;
  esac
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  main "$@"
fi

#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

# Services needed by the desktop are automatic. Hardware/features the user may
# not use are opt-in so running the installer does not silently start them.
# Docker is offered as its socket, never the service: the daemon then stays off
# (and out of boot and RAM) until the first docker command activates it.
DEFAULT_UNITS=(NetworkManager.service power-profiles-daemon.service)
OPTIONAL_UNITS=(bluetooth.service docker.socket thermald.service)

enable_unit() {
  local unit="$1"
  if systemctl list-unit-files "${unit}" --no-legend 2>/dev/null | grep -q .; then
    sudo systemctl enable --now "${unit}"
    log "Enabled ${unit}"
  else
    log "Skipped ${unit} (not installed)"
  fi
}

offer_docker_group() {
  local current_user answer
  current_user="$(id -un)"

  getent group docker >/dev/null 2>&1 || return 0
  if id -nG "${current_user}" | tr ' ' '\n' | grep -qx docker; then
    log "${current_user} is already in the docker group"
    return 0
  fi

  warn "The docker group grants root-equivalent access."
  printf 'Add %s to the docker group? [y/N]: ' "${current_user}"
  read -r answer || answer=""
  if [[ ${answer} =~ ^[Yy]$ ]]; then
    sudo usermod -aG docker "${current_user}"
    log "Added ${current_user} to the docker group; log out and back in before using docker"
  else
    log "Skipped docker group membership; use sudo docker instead"
  fi
}

main() {
  require_arch
  local unit answer
  for unit in "${DEFAULT_UNITS[@]}"; do
    enable_unit "${unit}"
  done
  for unit in "${OPTIONAL_UNITS[@]}"; do
    printf 'Enable optional %s? [y/N]: ' "${unit}"
    read -r answer || answer=""
    if [[ ${answer} =~ ^[Yy]$ ]]; then
      enable_unit "${unit}"
      [[ ${unit} != docker.socket ]] || offer_docker_group
    else
      log "Skipped optional ${unit}"
    fi
  done
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  main "$@"
fi

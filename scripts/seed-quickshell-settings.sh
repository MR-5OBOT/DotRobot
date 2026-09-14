#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

DEFAULT_SETTINGS="${DOTFILES_DIR}/.config/quickshell/widgets/settings.json"
SETTINGS_FILE="${XDG_CONFIG_HOME:-${HOME}/.config}/mr5obot/settings.json"

main() {
  if [[ -e "${SETTINGS_FILE}" || -L "${SETTINGS_FILE}" ]]; then
    log "Kept existing ${SETTINGS_FILE}"
    return 0
  fi

  install -Dm 644 "${DEFAULT_SETTINGS}" "${SETTINGS_FILE}"
  log "Seeded ${SETTINGS_FILE}"
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  main "$@"
fi

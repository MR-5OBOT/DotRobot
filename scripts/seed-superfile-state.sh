#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

# superfile keeps the "show hidden files" toggle as runtime state under
# ~/.local/share rather than in config.toml, so it cannot be symlinked from the
# repo. Seed it once on a fresh install; superfile owns the file afterwards and
# pressing '.' in the browser stays authoritative.
STATE_FILE="${XDG_DATA_HOME:-$HOME/.local/share}/superfile/toggleDotFile"

main() {
  if [[ -s "${STATE_FILE}" ]]; then
    log "superfile dotfile toggle already set ($(cat "${STATE_FILE}")), leaving it"
    return 0
  fi

  mkdir -p "$(dirname "${STATE_FILE}")"
  printf 'true' > "${STATE_FILE}"
  log "Seeded superfile to show hidden files"
}

main "$@"

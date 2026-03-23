#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

main() {
  command -v xdg-user-dirs-update >/dev/null 2>&1 || die "xdg-user-dirs-update is not installed."
  xdg-user-dirs-update
  mkdir -p "${HOME}/Pictures/Screenshots"
  log "User directories are ready"
}

main "$@"

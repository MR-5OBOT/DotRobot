#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

main() {
  local src profile_root profile
  src="${ASSETS_DIR}/browser/firefox/junkyfox"
  profile_root="${HOME}/.mozilla/firefox"

  [[ -d "${src}" ]] || die "Firefox theme assets not found."
  [[ -d "${profile_root}" ]] || die "Firefox profiles directory not found."

  profile="$(find "${profile_root}" -maxdepth 1 -type d -name '*.default-release' -print -quit)"
  [[ -n "${profile}" ]] || die "No Firefox default-release profile found."

  symlink_path "${src}/chrome" "${profile}/chrome"
  symlink_path "${ASSETS_DIR}/browser/firefox/user.js" "${profile}/user.js"
}

main "$@"

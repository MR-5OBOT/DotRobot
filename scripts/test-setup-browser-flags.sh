#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT
mkdir -p "${tmp}/bin" "${tmp}/cfg"

# Wrapper scripts as packages install them, plus a binary that only mentions a
# flags file in its data and must not be offered.
printf '#!/bin/bash\nCONF_FILE="${XDG_CONFIG_HOME}/brave-origin-flags.conf"\n' > "${tmp}/bin/brave-origin"
printf '#!/bin/bash\n[[ -f ~/.config/vivaldi-stable.conf ]]\n' > "${tmp}/bin/vivaldi-stable"
printf '\0\1chrome-flags.conf' > "${tmp}/bin/some-binary"

printf 'a\n' | LAUNCHER_DIR="${tmp}/bin" XDG_CONFIG_HOME="${tmp}/cfg" XDG_STATE_HOME="${tmp}/state" \
  bash "${SCRIPT_DIR}/setup-browser-flags.sh" > /dev/null 2>&1

[[ -L "${tmp}/cfg/brave-origin-flags.conf" ]]
[[ -L "${tmp}/cfg/vivaldi-stable.conf" ]]
[[ ! -e "${tmp}/cfg/chrome-flags.conf" ]]
printf 'browser flags discovery test passed\n'

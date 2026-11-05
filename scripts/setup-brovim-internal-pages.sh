#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly BROVIM_DIR="${1:-${REPO_ROOT}/../brovim}"
readonly FLAGS_FILE="${REPO_ROOT}/assets/presets/browser-flags/helium-brovim.conf"
readonly CONFIG_DIR="${XDG_CONFIG_HOME:-${HOME}/.config}"
readonly TARGET="${CONFIG_DIR}/helium-browser-flags.conf"

if [[ ! -f "${BROVIM_DIR}/manifest.json" || ! -f "${FLAGS_FILE}" ]]; then
  printf 'Usage: %s /path/to/brovim\nMissing Brovim source or the Helium flags preset.\n' "$0" >&2
  exit 1
fi

mkdir -p "${CONFIG_DIR}"
if [[ ! -L "${TARGET}" || "$(readlink "${TARGET}")" != "${FLAGS_FILE}" ]]; then
  if [[ -e "${TARGET}" || -L "${TARGET}" ]]; then
    backup="${TARGET}.bak.$(date +%Y%m%dT%H%M%S).$$"
    mv -- "${TARGET}" "${backup}"
    printf 'Previous flags saved at %s\n' "${backup}"
  fi
  ln -s -- "${FLAGS_FILE}" "${TARGET}"
fi

cat <<EOF
Helium's developer override is saved in ${TARGET} for the next browser launch.
It permits extensions with chrome:// permissions to read and modify browser pages.
Fully quit Helium and reopen it through the helium-browser launcher.
Reloading the extension alone does not apply a browser startup flag.
Keep Brovim loaded unpacked from ${BROVIM_DIR}; reload it in chrome://extensions.
On a fresh install, load that repository root once. Settings and Alt+Q stay with that copy.
Options > General > Use Brovim on browser pages is on by default; switch it off there if desired.
The launcher reads this flags file on every start, including after a reboot.
To remove the browser override, restore the flags backup (or link chromium-hwaccel.conf),
then fully restart Helium. No desktop-file editing or separate extension build is needed.
EOF

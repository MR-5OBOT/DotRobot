#!/usr/bin/env bash
set -euo pipefail

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT
ANDROID_HOME="${tmp_dir}/sdk" source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/dotfiles/.local/bin/droid"
log() { :; }
curl() { printf '<xml/>\n'; }
python3() { printf 'package.zip checksum 1\n'; }
fetch() { mkdir -p "$(dirname "$4")"; touch "$4"; }
unzip() { mkdir -p "$4/package"; [[ ${VALID:-1} == 1 ]] && touch "$4/package/source.properties"; }

dest="${tmp_dir}/installed"
mkdir -p "${dest}"
printf 'old\n' >"${dest}/marker"
VALID=0
! (install_pkg index.xml test-package "${dest}") >/dev/null 2>&1
[[ "$(<"${dest}/marker")" == old ]]

VALID=1
install_pkg index.xml test-package "${dest}"
[[ -f "${dest}/source.properties" && ! -e "${dest}/marker" ]]

printf 'droid tests passed\n'

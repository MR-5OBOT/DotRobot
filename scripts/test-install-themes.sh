#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/install-themes.sh"
log() { :; }

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT
target="${tmp_dir}/Theme"
mkdir -p "${target}" "${tmp_dir}/new" "${tmp_dir}/newer"
printf 'original\n' >"${target}/version"
printf 'new\n' >"${tmp_dir}/new/version"
printf 'newer\n' >"${tmp_dir}/newer/version"

install_theme "${tmp_dir}/new" "${target}"
install_theme "${tmp_dir}/newer" "${target}"

[[ "$(<"${tmp_dir}/.Theme.dotrobot.bak/version")" == original ]]
[[ "$(<"${target}/version")" == newer ]]

printf 'install-themes tests passed\n'

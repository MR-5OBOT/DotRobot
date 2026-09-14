#!/usr/bin/env bash
# Starts the island bar (the repo's island/ directory). It runs from a copy under
# ~/.local/share rather than from the repo, so nothing it writes next to itself
# lands in git; the copy is refreshed from the repo on every login so the dotfiles
# stay the source of truth. ~/.config/hypr is a symlink into the repo, which is
# how the repo is found on any machine.

set -euo pipefail

repo="$(readlink -f "${HOME}/.config/hypr")/../../../island"
dest="${XDG_DATA_HOME:-${HOME}/.local/share}/quickshell/island"

if [[ -d "${repo}" ]]; then
  mkdir -p "${dest}"
  cp -a "${repo}/." "${dest}/"
fi

exec "${dest}/launch.sh"

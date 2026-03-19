#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

link_config_tree() {
  local item
  for item in "${DOTFILES_DIR}/.config"/*; do
    [[ -e "${item}" ]] || continue
    symlink_path "${item}" "${HOME}/.config/$(basename "${item}")"
  done
}

link_local_bin() {
  mkdir -p "${HOME}/.local/bin"
  local item
  for item in "${DOTFILES_DIR}/.local/bin"/*; do
    [[ -e "${item}" ]] || continue
    symlink_path "${item}" "${HOME}/.local/bin/$(basename "${item}")"
  done
}

main() {
  symlink_path "${DOTFILES_DIR}/.zshrc" "${HOME}/.zshrc"
  symlink_path "${DOTFILES_DIR}/.gitconfig" "${HOME}/.gitconfig"
  link_config_tree
  link_local_bin

  if [[ -d "${ASSETS_DIR}/wallpapers" ]]; then
    mkdir -p "${HOME}/Pictures"
    symlink_path "${ASSETS_DIR}/wallpapers" "${HOME}/Pictures/wallpapers"
  fi
}

main "$@"

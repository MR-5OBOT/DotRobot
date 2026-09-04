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
  local item

  # Link scripts one by one so tool installers (uv, claude) can drop their
  # own shims into ~/.local/bin without writing into the repo.
  if [[ -L "${HOME}/.local/bin" ]]; then
    rm "${HOME}/.local/bin"
    log "Removed legacy ~/.local/bin directory symlink"
  fi
  mkdir -p "${HOME}/.local/bin"
  for item in "${DOTFILES_DIR}/.local/bin"/*; do
    [[ -e "${item}" ]] || continue
    symlink_path "${item}" "${HOME}/.local/bin/$(basename "${item}")"
  done
}

link_local_share_applications() {
  local applications_dir="${DOTFILES_DIR}/.local/share/applications"
  local item

  [[ -d "${applications_dir}" ]] || return 0

  mkdir -p "${HOME}/.local/share/applications"
  for item in "${applications_dir}"/*; do
    [[ -e "${item}" ]] || continue
    symlink_path "${item}" "${HOME}/.local/share/applications/$(basename "${item}")"
  done
}

link_local_share_themes() {
  local themes_dir="${DOTFILES_DIR}/.local/share/themes"
  local item

  [[ -d "${themes_dir}" ]] || return 0

  mkdir -p "${HOME}/.local/share/themes"
  for item in "${themes_dir}"/*; do
    [[ -e "${item}" ]] || continue
    symlink_path "${item}" "${HOME}/.local/share/themes/$(basename "${item}")"
  done
}

main() {
  local icons_dir="${XDG_DATA_HOME:-${HOME}/.local/share}/icons"

  symlink_path "${DOTFILES_DIR}/.gitconfig" "${HOME}/.gitconfig"
  symlink_path "${DOTFILES_DIR}/.visidatarc" "${HOME}/.visidatarc"
  link_config_tree
  link_local_bin
  link_local_share_applications
  link_local_share_themes

  mkdir -p "${icons_dir}"
  unzip -q -o "${ASSETS_DIR}/icons/gruvbox-plus-icon-pack-6.2.0.zip" -d "${icons_dir}"
  tar -xzf "${ASSETS_DIR}/icons/volantes-light-cursors.tar.gz" -C "${icons_dir}"
  log "Installed icon and cursor themes"

  "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/seed-superfile-state.sh"

  if [[ -d "${ASSETS_DIR}/wallpapers" ]]; then
    mkdir -p "${HOME}/Pictures"
    symlink_path "${ASSETS_DIR}/wallpapers" "${HOME}/Pictures/wallpapers"
  fi
}

main "$@"

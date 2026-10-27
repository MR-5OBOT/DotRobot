#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

# Link each entry of $1 into $2 one by one, so $2 stays a real directory that
# tool installers (uv, claude, ...) can also drop their own files into.
link_children() {
  local src="$1" dest="$2" item

  [[ -d "${src}" ]] || return 0
  mkdir -p "${dest}"
  for item in "${src}"/*; do
    [[ -e "${item}" ]] || continue
    symlink_path "${item}" "${dest}/$(basename "${item}")"
  done
}

main() {
  local icons_dir="${XDG_DATA_HOME:-${HOME}/.local/share}/icons"

  symlink_path "${DOTFILES_DIR}/.gitconfig" "${HOME}/.gitconfig"
  link_children "${DOTFILES_DIR}/.config" "${HOME}/.config"
  # ~/.local/bin used to be one symlink into the repo; it is a real directory now.
  if [[ -L "${HOME}/.local/bin" ]]; then
    rm "${HOME}/.local/bin"
    log "Removed legacy ~/.local/bin directory symlink"
  fi
  link_children "${DOTFILES_DIR}/.local/bin" "${HOME}/.local/bin"
  link_children "${DOTFILES_DIR}/.local/share/applications" "${HOME}/.local/share/applications"
  link_children "${DOTFILES_DIR}/.local/share/themes" "${HOME}/.local/share/themes"

  mkdir -p "${icons_dir}"
  fetch_release_asset SylEleuth/gruvbox-plus-icon-pack v6.2.0 \
    gruvbox-plus-icon-pack-6.2.0.zip \
    0fe48f86e707538462cf49b35352e7684924690b7e6e524c02c039afa7d3010d
  unzip -q -o "${FETCHED_ASSET}" -d "${icons_dir}"
  tar -xzf "${ASSETS_DIR}/icons/volantes-light-cursors.tar.gz" -C "${icons_dir}"
  log "Installed icon and cursor themes"

  "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/seed-superfile-state.sh"
  "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/setup-claude.sh"

  if [[ -d "${ASSETS_DIR}/wallpapers" ]]; then
    mkdir -p "${HOME}/Pictures"
    symlink_path "${ASSETS_DIR}/wallpapers" "${HOME}/Pictures/wallpapers"
  fi
}

main "$@"

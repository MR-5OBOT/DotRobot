#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

# Link each entry of $1 into $2 one by one, so $2 stays a real directory that
# tool installers (uv, claude, ...) can also drop their own files into.
# Further arguments name entries to leave out.
link_children() {
  local src="$1" dest="$2" item
  shift 2

  [[ -d "${src}" ]] || return 0
  mkdir -p "${dest}"
  for item in "${src}"/*; do
    [[ -e "${item}" ]] || continue
    [[ " $* " == *" ${item##*/} "* ]] && continue
    symlink_path "${item}" "${dest}/$(basename "${item}")"
  done
}

# Vesktop keeps the Discord session (login token) in ~/.config/vesktop, so that
# stays a real directory and only themes/ comes from the repo. It used to be one
# symlink into the repo; move the session found there out first.
link_vesktop() {
  local dir="${HOME}/.config/vesktop" repo_dir="${DOTFILES_DIR}/.config/vesktop"

  if [[ -L "${dir}" ]]; then
    if [[ "$(readlink "${dir}")" != "${repo_dir}" ]]; then
      warn "${dir} links somewhere else; left it alone"
      return 0
    fi
    if pgrep -x vesktop >/dev/null; then
      warn "Close Vesktop and re-run to move its session out of the repo"
      return 0
    fi
    rm "${dir}"
    mkdir -p "${dir}"
    find "${repo_dir}" -mindepth 1 -maxdepth 1 ! -name themes -exec mv -t "${dir}" -- {} +
    log "Moved Vesktop's session out of the repo into ${dir}"
  fi
  link_children "${repo_dir}" "${dir}"
}

# Qt reads stylesheet paths and url()s literally, so the files in .gitattributes
# hold @HOME@ in git. This filter writes your home on checkout and puts @HOME@
# back on commit; files still holding @HOME@ (fresh clone) are checked out again.
setup_home_filter() {
  local file
  git -C "${REPO_ROOT}" config filter.home.smudge 'sed "s|@HOME@|$HOME|g"'
  git -C "${REPO_ROOT}" config filter.home.clean 'sed "s|$HOME|@HOME@|g"'
  while IFS= read -r file; do
    grep -q '@HOME@' "${REPO_ROOT}/${file}" && git -C "${REPO_ROOT}" diff --quiet -- "${file}" || continue
    rm -f -- "${REPO_ROOT}/${file}"
    git -C "${REPO_ROOT}" checkout -- "${file}"
  done < <(git -C "${REPO_ROOT}" ls-files -- ':(attr:filter=home)')
  log "Qt config paths point at ${HOME}"
}

main() {
  local icons_dir="${XDG_DATA_HOME:-${HOME}/.local/share}/icons"

  symlink_path "${DOTFILES_DIR}/.gitconfig" "${HOME}/.gitconfig"
  setup_home_filter
  link_children "${DOTFILES_DIR}/.config" "${HOME}/.config" vesktop
  link_vesktop
  # ~/.local/bin used to be one symlink into the repo; it is a real directory now.
  if [[ -L "${HOME}/.local/bin" ]]; then
    rm "${HOME}/.local/bin"
    log "Removed legacy ~/.local/bin directory symlink"
  fi
  link_children "${DOTFILES_DIR}/.local/bin" "${HOME}/.local/bin"
  link_children "${DOTFILES_DIR}/.local/share/applications" "${HOME}/.local/share/applications"
  link_children "${DOTFILES_DIR}/.local/share/themes" "${HOME}/.local/share/themes"
  link_children "${DOTFILES_DIR}/.local/share/color-schemes" "${HOME}/.local/share/color-schemes"

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

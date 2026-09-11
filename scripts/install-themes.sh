#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

# Icon/cursor packs and GTK themes ship as archives under assets/ because they
# are upstream releases, not files we edit. Extract each one and drop the theme
# directories it contains where GTK looks for them.
ICONS_DEST="${ICONS_DEST:-${HOME}/.icons}"
THEMES_DEST="${THEMES_DEST:-${HOME}/.themes}"

WORKDIR=""

cleanup() {
  [[ -n "${WORKDIR}" ]] || return 0
  rm -rf "${WORKDIR}"
  WORKDIR=""
}
trap cleanup EXIT

archive_kind() {
  case "$1" in
    *.zip) printf 'zip' ;;
    *.tar | *.tar.* | *.tgz | *.txz | *.tbz2 | *.tzst) printf 'tar' ;;
    *) return 1 ;;
  esac
}

archive_stem() {
  basename "$1" | sed -E 's/\.(zip|tgz|txz|tbz2|tzst|tar(\.(gz|xz|bz2|zst))?)$//'
}

extract_archive() {
  local archive="$1"
  local workdir="$2"

  case "$(archive_kind "${archive}")" in
    zip)
      command -v unzip >/dev/null 2>&1 || die "unzip is not installed."
      unzip -q -o "${archive}" -d "${workdir}"
      ;;
    tar) tar -xf "${archive}" -C "${workdir}" ;;
  esac
}

is_theme_root() {
  local dir="$1"

  [[ -e "${dir}/index.theme" || -e "${dir}/cursor.theme" || -d "${dir}/cursors" ]] && return 0
  compgen -G "${dir}/gtk-*" >/dev/null && return 0
  return 1
}

# Some packs wrap the real theme in an extra directory (Foo.zip -> Foo/Foo/).
# Only step down when the single subdirectory is recognisably a theme root, so
# a cursor pack holding just cursors/ is not mistaken for a wrapper.
theme_root() {
  local dir="$1"
  local -a entries
  local depth

  for depth in 1 2 3; do
    is_theme_root "${dir}" && break
    mapfile -t entries < <(find "${dir}" -mindepth 1 -maxdepth 1)
    [[ ${#entries[@]} -eq 1 && -d "${entries[0]}" ]] || break
    is_theme_root "${entries[0]}" || break
    dir="${entries[0]}"
  done

  printf '%s' "${dir}"
}

install_theme() {
  local source="$1"
  local target="$2"

  if [[ -e "${target}" || -L "${target}" ]]; then
    rm -rf "${target}"
    log "Removed existing ${target}"
  fi

  mv "${source}" "${target}"
  log "Installed ${target}"
}

install_archive() {
  local archive="$1"
  local dest_dir="$2"
  local -a entries
  local entry

  # Extract inside the destination so installing is a rename, not a copy.
  WORKDIR="$(mktemp -d "${dest_dir}/.dotrobot-extract.XXXXXX")"
  extract_archive "${archive}" "${WORKDIR}"
  rm -rf "${WORKDIR}/__MACOSX"

  mapfile -t entries < <(find "${WORKDIR}" -mindepth 1 -maxdepth 1)
  if [[ ${#entries[@]} -eq 0 ]]; then
    warn "$(basename "${archive}") extracted to nothing"
    cleanup
    return 0
  fi

  # Loose files at the top mean a theme shipped without its own directory;
  # keep the extraction directory as that theme, named after the archive.
  for entry in "${entries[@]}"; do
    if [[ ! -d "${entry}" ]]; then
      local wrapped="${WORKDIR}"
      WORKDIR=""
      chmod 755 "${wrapped}"
      install_theme "${wrapped}" "${dest_dir}/$(archive_stem "${archive}")"
      return 0
    fi
  done

  for entry in "${entries[@]}"; do
    entry="$(theme_root "${entry}")"
    install_theme "${entry}" "${dest_dir}/$(basename "${entry}")"
  done
  cleanup
}

install_group() {
  local source_dir="$1"
  local dest_dir="$2"
  local archive
  local found=0

  if [[ ! -d "${source_dir}" ]]; then
    warn "No ${source_dir} directory, nothing to install"
    return 0
  fi

  mkdir -p "${dest_dir}"
  for archive in "${source_dir}"/*; do
    [[ -f "${archive}" ]] || continue
    if ! archive_kind "${archive}" >/dev/null; then
      warn "Skipping $(basename "${archive}"): not an archive"
      continue
    fi
    found=1
    log "Extracting $(basename "${archive}") -> ${dest_dir}"
    install_archive "${archive}" "${dest_dir}"
  done

  [[ ${found} -eq 1 ]] || warn "No archives in ${source_dir}"
}

# The gruvbox pack is an upstream release, so it is fetched and checksummed at
# install time instead of living in the repo; anything still under assets/icons
# (the cursor theme) is installed from disk as before.
install_icons() {
  mkdir -p "${ICONS_DEST}"
  fetch_release_asset SylEleuth/gruvbox-plus-icon-pack v6.2.0 \
    gruvbox-plus-icon-pack-6.2.0.zip \
    0fe48f86e707538462cf49b35352e7684924690b7e6e524c02c039afa7d3010d
  log "Extracting $(basename "${FETCHED_ASSET}") -> ${ICONS_DEST}"
  install_archive "${FETCHED_ASSET}" "${ICONS_DEST}"
  install_group "${ASSETS_DIR}/icons" "${ICONS_DEST}"
}

main() {
  local group="${1:-all}"

  case "${group}" in
    icons) install_icons ;;
    themes) install_group "${ASSETS_DIR}/themes" "${THEMES_DEST}" ;;
    all)
      install_icons
      install_group "${ASSETS_DIR}/themes" "${THEMES_DEST}"
      ;;
    *) die "Usage: $(basename "$0") [icons|themes|all]" ;;
  esac

  log "Icon and GTK themes are installed"
}

main "$@"

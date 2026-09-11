#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOTFILES_DIR="${REPO_ROOT}/dotfiles"
PACKAGES_DIR="${REPO_ROOT}/packages/arch"
ASSETS_DIR="${REPO_ROOT}/assets"
LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dotrobot"
mkdir -p "${LOG_DIR}"
LOG_FILE="${LOG_DIR}/install.log"

log() {
  printf '[*] %s\n' "$*" | tee -a "${LOG_FILE}"
}

warn() {
  printf '[!] %s\n' "$*" | tee -a "${LOG_FILE}" >&2
}

die() {
  warn "$*"
  exit 1
}

is_arch() {
  [[ -f /etc/arch-release ]] && command -v pacman >/dev/null 2>&1
}

require_arch() {
  is_arch || die "This setup only supports Arch Linux."
}

prompt_step() {
  local label="$1"
  local answer

  while true; do
    printf '%s [Y/n]: ' "${label}"
    read -r answer
    answer="${answer:-y}"
    case "${answer}" in
      [Yy]) return 0 ;;
      [Nn]) return 1 ;;
      *) warn "Answer with y or n." ;;
    esac
  done
}

symlink_path() {
  local source="$1"
  local target="$2"

  mkdir -p "$(dirname "${target}")"
  if [[ -L "${target}" ]] && [[ "$(readlink "${target}")" == "${source}" ]]; then
    log "Already linked ${target}"
    return 0
  fi

  if [[ -e "${target}" || -L "${target}" ]]; then
    rm -rf "${target}"
    log "Removed existing ${target}"
  fi

  ln -sfnT "${source}" "${target}"
  log "Linked ${target} -> ${source}"
}

# Large upstream archives are fetched at install time rather than vendored, so
# the repo stays small. Pinned to a release tag and verified by checksum, so a
# fresh install is still byte-for-byte reproducible. Cached under XDG_CACHE_HOME
# so re-running the installer does not re-download. Sets FETCHED_ASSET rather
# than printing the path, because log() writes to stdout.
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/dotrobot"
FETCHED_ASSET=""

fetch_release_asset() {
  local repo="$1"
  local tag="$2"
  local asset="$3"
  local sha="$4"
  local dest="${CACHE_DIR}/${asset}"

  mkdir -p "${CACHE_DIR}"
  if [[ -f "${dest}" ]] && printf '%s  %s' "${sha}" "${dest}" | sha256sum --check --status 2>/dev/null; then
    log "Using cached ${asset}"
    FETCHED_ASSET="${dest}"
    return 0
  fi

  log "Downloading ${asset} from ${repo} ${tag}"
  if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    gh release download "${tag}" --repo "${repo}" --pattern "${asset}" --dir "${CACHE_DIR}" --clobber
  elif command -v curl >/dev/null 2>&1; then
    curl -fsSL --retry 3 -o "${dest}" "https://github.com/${repo}/releases/download/${tag}/${asset}"
  else
    die "Need gh or curl to download ${asset}"
  fi

  printf '%s  %s' "${sha}" "${dest}" | sha256sum --check --status \
    || die "${asset} failed checksum verification"
  FETCHED_ASSET="${dest}"
}

read_package_file() {
  local file="$1"
  grep -Ev '^\s*($|#)' "${file}" | sed 's/[[:space:]]*$//'
}

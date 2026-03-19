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
    printf '%s [Y/n/s]: ' "${label}"
    read -r answer
    answer="${answer:-y}"
    case "${answer}" in
      [Yy]) return 0 ;;
      [Nn]|[Ss]) return 1 ;;
      *) warn "Answer with y, n, or s." ;;
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

  rm -rf "${target}"
  ln -sfn "${source}" "${target}"
  log "Linked ${target} -> ${source}"
}

read_package_file() {
  local file="$1"
  grep -Ev '^\s*($|#)' "${file}"
}

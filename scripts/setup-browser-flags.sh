#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

# Chromium-based browsers whose Arch launcher reads a flags file from
# $XDG_CONFIG_HOME, as "command:flags file". A browser is only offered when its
# installed launcher script actually mentions that file, so a package that drops
# or renames the feature is skipped instead of getting a file nothing reads.
readonly BROWSERS=(
  "chromium:chromium-flags.conf"
  "google-chrome-stable:chrome-flags.conf"
  "brave:brave-flags.conf"
  "helium-browser:helium-browser-flags.conf"
  "vivaldi-stable:vivaldi-stable.conf"
  "microsoft-edge-stable:microsoft-edge-stable-flags.conf"
)
readonly FLAGS_FILE="${DOTFILES_DIR}/browser-flags/chromium-hwaccel.conf"

# Binaries never read a flags file; only the wrapper scripts packages install do.
launcher_reads() {
  local cmd="$1" conf="$2" path

  path="$(command -v "${cmd}" 2>/dev/null)" || return 1
  path="$(readlink -f "${path}")"
  grep -Iq . "${path}" 2>/dev/null || return 1
  grep -Fq "${conf}" "${path}"
}

# symlink_path deletes whatever is at the target, so keep a hand-written flags
# file the user already has instead of silently losing it.
keep_existing() {
  local target="$1"

  if [[ -L "${target}" && "$(readlink "${target}")" == "${FLAGS_FILE}" ]]; then
    return 0
  fi
  if [[ -e "${target}" || -L "${target}" ]]; then
    mv "${target}" "${target}.bak"
    warn "Moved your existing ${target} to ${target}.bak"
  fi
}

main() {
  local config_home="${XDG_CONFIG_HOME:-${HOME}/.config}"
  local entry answer i
  local -a found=()

  [[ -f "${FLAGS_FILE}" ]] || die "Missing ${FLAGS_FILE}"
  if ! vainfo 2>/dev/null | grep -q VAEntrypointVLD; then
    warn "vainfo reports no VA-API decode profiles; install your GPU's VA-API driver or the flags have nothing to use"
  fi

  for entry in "${BROWSERS[@]}"; do
    if launcher_reads "${entry%%:*}" "${entry#*:}"; then
      found+=("${entry}")
    fi
  done
  if ((${#found[@]} == 0)); then
    log "No installed browser reads a flags file; nothing to link"
    return 0
  fi

  printf 'Browsers that read a flags file:\n'
  for i in "${!found[@]}"; do
    printf '  %d) %s -> %s/%s\n' "$((i + 1))" "${found[i]%%:*}" "${config_home}" "${found[i]#*:}"
  done
  printf 'Link hardware video flags for [numbers, a = all, Enter = none]: '
  read -r answer

  if [[ -z "${answer}" ]]; then
    log "Skipped browser flags"
    return 0
  fi
  if [[ "${answer}" == "a" ]]; then
    answer="$(seq -s ' ' 1 "${#found[@]}")"
  fi

  for i in ${answer//,/ }; do
    if ! [[ "${i}" =~ ^[0-9]+$ ]] || ((i < 1 || i > ${#found[@]})); then
      warn "Ignoring '${i}'"
      continue
    fi
    entry="${found[i - 1]}"
    keep_existing "${config_home}/${entry#*:}"
    symlink_path "${FLAGS_FILE}" "${config_home}/${entry#*:}"
  done
  log "Restart each linked browser, then check chrome://media-internals (video_decoder) while a video plays"
}

main "$@"

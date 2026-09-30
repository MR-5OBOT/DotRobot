#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

readonly FLAGS_FILE="${DOTFILES_DIR}/browser-flags/chromium-hwaccel.conf"
readonly LAUNCHER_DIR="${LAUNCHER_DIR:-/usr/bin}"

# Chromium-based packages (chromium, chrome, brave, brave-origin, helium, edge, ...)
# install a wrapper script that reads "<name>-flags.conf" from $XDG_CONFIG_HOME;
# vivaldi's is "vivaldi-*.conf". Find them by scanning the wrappers instead of
# keeping a list, so a new browser or a renamed package (brave-origin) is picked
# up. Prints "command:flags file", one per flags file. -I skips real binaries,
# which never read one.
find_launchers() {
  local path conf

  while IFS= read -r path; do
    { grep -IoE -- '[[:alnum:]._-]+-flags\.conf|vivaldi[[:alnum:]-]*\.conf' "${path}" || true; } | sort -u |
      while IFS= read -r conf; do printf '%s:%s\n' "${path##*/}" "${conf}"; done
  done < <(grep -IlE -- '-flags\.conf|vivaldi[[:alnum:]-]*\.conf' "${LAUNCHER_DIR}"/* 2>/dev/null) |
    sort -t: -k2,2 -u
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

  mapfile -t found < <(find_launchers)
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

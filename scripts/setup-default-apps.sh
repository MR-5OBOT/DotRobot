#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

# A type with no default goes to whichever installed app claims it first, which
# can be a browser you don't use, so name a default for every type a browser claims.
readonly BROWSER_TYPES=(
  text/html application/xhtml+xml application/xml text/xml application/rss+xml application/rdf+xml
  image/jpeg image/png image/webp image/gif
  x-scheme-handler/http x-scheme-handler/https x-scheme-handler/about x-scheme-handler/unknown
  x-scheme-handler/mailto
)
readonly PDF_VIEWER="org.pwmt.zathura-pdf-mupdf.desktop"

# Prints "id<TAB>name" for every desktop entry that opens https links. User
# entries come first, so one that overrides a system entry of the same id wins.
find_browsers() {
  local dir path id
  local -A seen=()
  local IFS=:

  for dir in "${XDG_DATA_HOME:-${HOME}/.local/share}" ${XDG_DATA_DIRS:-/usr/local/share:/usr/share}; do
    for path in "${dir}"/applications/*.desktop; do
      id="${path##*/}"
      [[ -f "${path}" && -z "${seen[${id}]:-}" ]] || continue
      seen[${id}]=1
      grep -qE '^MimeType=.*x-scheme-handler/https(;|$)' "${path}" || continue
      printf '%s\t%s\n' "${id}" "$(grep -m1 '^Name=' "${path}" | cut -d= -f2-)"
    done
  done
}

main() {
  local current answer i id mark browser pdf
  local -a browsers=()

  command -v xdg-mime >/dev/null 2>&1 || die "xdg-mime is not installed (xdg-utils)"
  mapfile -t browsers < <(find_browsers)
  ((${#browsers[@]} > 0)) || die "No installed browser opens web links; install one first"

  current="$(xdg-mime query default x-scheme-handler/https)"
  printf 'Installed browsers:\n'
  for i in "${!browsers[@]}"; do
    id="${browsers[i]%%$'\t'*}"
    mark=""
    [[ "${id}" == "${current}" ]] && mark=" [current]"
    printf '  %d) %s (%s)%s\n' "$((i + 1))" "${browsers[i]#*$'\t'}" "${id}" "${mark}"
  done
  printf 'Default browser [number, Enter = leave as is]: '
  read -r answer

  if [[ -z "${answer}" ]]; then
    log "Left the default browser as is"
    return 0
  fi
  if ! [[ "${answer}" =~ ^[1-9][0-9]*$ ]] || ((answer > ${#browsers[@]})); then
    die "No browser numbered '${answer}'"
  fi

  browser="${browsers[answer - 1]%%$'\t'*}"
  xdg-mime default "${browser}" "${BROWSER_TYPES[@]}"
  pdf="${browser}"
  [[ -f "/usr/share/applications/${PDF_VIEWER}" ]] && pdf="${PDF_VIEWER}"
  xdg-mime default "${pdf}" application/pdf
  log "${browser} is the default browser; ${pdf} opens PDFs"
}

main "$@"

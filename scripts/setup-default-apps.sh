#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

# A type with no default goes to whichever installed app claims it first, which
# can be a browser you don't use, so name a default for every type a browser claims.
# Web pages and links always go to the chosen browser.
readonly WEB_TYPES=(
  text/html application/xhtml+xml
  x-scheme-handler/http x-scheme-handler/https x-scheme-handler/about x-scheme-handler/unknown
)
# Browsers claim these too, but you may have picked another app for them (an image
# viewer, a mail client), so they are only set while unset or already a browser.
readonly OTHER_TYPES=(
  application/xml text/xml application/rss+xml application/rdf+xml
  image/jpeg image/png image/webp image/gif
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
  local current answer i id mark browser type others ids
  local -a browsers=()

  # Optional step: problems warn and return 0, so install.sh (set -e) goes on to its next steps.
  if ! command -v xdg-mime >/dev/null 2>&1; then
    warn "xdg-mime is not installed (xdg-utils); skipped the default browser"
    return 0
  fi
  mapfile -t browsers < <(find_browsers)
  if ((${#browsers[@]} == 0)); then
    warn "No installed browser opens web links yet; run scripts/setup-default-apps.sh after installing one"
    return 0
  fi

  current="$(xdg-mime query default x-scheme-handler/https || true)"
  printf 'Installed browsers:\n'
  for i in "${!browsers[@]}"; do
    id="${browsers[i]%%$'\t'*}"
    mark=""
    [[ "${id}" == "${current}" ]] && mark=" [current]"
    printf '  %d) %s (%s)%s\n' "$((i + 1))" "${browsers[i]#*$'\t'}" "${id}" "${mark}"
  done
  while true; do
    printf 'Default browser [number, Enter = leave as is]: '
    read -r answer || answer=""   # end of input counts as Enter
    if [[ -z "${answer}" ]]; then
      log "Left the default browser as is"
      return 0
    fi
    if [[ "${answer}" =~ ^[1-9][0-9]*$ ]] && ((answer <= ${#browsers[@]})); then
      break
    fi
    warn "No browser numbered '${answer}'; pick a listed number or press Enter"
  done

  browser="${browsers[answer - 1]%%$'\t'*}"
  xdg-mime default "${browser}" "${WEB_TYPES[@]}"

  # Every installed browser's id, space-separated, to tell "a browser has it" apart from your own choice.
  ids=" "
  for i in "${!browsers[@]}"; do ids+="${browsers[i]%%$'\t'*} "; done
  others=(application/pdf)
  [[ -f "/usr/share/applications/${PDF_VIEWER}" ]] && xdg-mime default "${PDF_VIEWER}" application/pdf && others=()
  for type in "${OTHER_TYPES[@]}" "${others[@]}"; do
    current="$(xdg-mime query default "${type}" || true)"
    if [[ -z "${current}" || "${ids}" == *" ${current} "* ]]; then
      xdg-mime default "${browser}" "${type}"
    fi
  done
  log "${browser} is the default browser; $(xdg-mime query default application/pdf || true) opens PDFs"
}

main "$@"

#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

# Claude Code reads its user config from CLAUDE_CONFIG_DIR, falling back to ~/.claude.
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-${HOME}/.claude}"
CLAUDE_DOTFILES="${DOTFILES_DIR}/.claude"
SETTINGS_FILE="${CLAUDE_DIR}/settings.json"
STATUSLINE_SCRIPT="statusline-command.sh"

link_claude_files() {
  local item

  [[ -d "${CLAUDE_DOTFILES}" ]] || return 0

  mkdir -p "${CLAUDE_DIR}"
  for item in "${CLAUDE_DOTFILES}"/*; do
    [[ -e "${item}" ]] || continue
    symlink_path "${item}" "${CLAUDE_DIR}/$(basename "${item}")"
  done
}

# Claude Code writes settings.json itself (/model, /config), so keep it a
# real file and only merge in the statusLine key.
set_statusline() {
  local script="${CLAUDE_DIR}/${STATUSLINE_SCRIPT}"
  local command tmp

  [[ -e "${CLAUDE_DOTFILES}/${STATUSLINE_SCRIPT}" ]] || return 0
  if ! command -v jq >/dev/null 2>&1; then
    warn "jq not found; add statusLine to ${SETTINGS_FILE} by hand"
    return 0
  fi

  command="bash ${script}"
  [[ "${script}" == "${HOME}"/* ]] && command="bash ~/${script#"${HOME}"/}"
  [[ -s "${SETTINGS_FILE}" ]] || printf '{}\n' > "${SETTINGS_FILE}"
  tmp="$(mktemp)"
  if jq --arg cmd "${command}" '.statusLine = {type: "command", command: $cmd}' \
      "${SETTINGS_FILE}" > "${tmp}"; then
    cat "${tmp}" > "${SETTINGS_FILE}"
    log "Set statusLine in ${SETTINGS_FILE} to: ${command}"
  else
    warn "Could not parse ${SETTINGS_FILE}; statusLine not set"
  fi
  rm -f "${tmp}"
}

main() {
  link_claude_files
  set_statusline
}

main "$@"

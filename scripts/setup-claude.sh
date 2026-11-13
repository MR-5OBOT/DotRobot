#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

# Claude Code reads its user config from CLAUDE_CONFIG_DIR, falling back to ~/.claude.
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-${HOME}/.claude}"
CLAUDE_DOTFILES="${DOTFILES_DIR}/.claude"
SETTINGS_FILE="${CLAUDE_DIR}/settings.json"
STATUSLINE_SCRIPT="statusline-command.sh"

# Claude Code writes settings.json itself
# (model, plugins, theme), so keep it a real file and only merge in statusLine.
set_statusline() {
  local script="${CLAUDE_DIR}/${STATUSLINE_SCRIPT}"
  local command tmp

  [[ -e "${CLAUDE_DOTFILES}/${STATUSLINE_SCRIPT}" ]] || return 0
  symlink_path "${CLAUDE_DOTFILES}/${STATUSLINE_SCRIPT}" "${script}"
  if ! command -v jq >/dev/null 2>&1; then
    warn "jq not found; add statusLine to ${SETTINGS_FILE} by hand"
    return 0
  fi

  printf -v command 'bash %q' "${script}"
  [[ -s "${SETTINGS_FILE}" ]] || printf '{}\n' > "${SETTINGS_FILE}"
  tmp="$(mktemp "${CLAUDE_DIR}/.settings.json.XXXXXX")"
  if jq --arg cmd "${command}" '.statusLine = {type: "command", command: $cmd}' \
      "${SETTINGS_FILE}" > "${tmp}"; then
    chmod --reference="${SETTINGS_FILE}" "${tmp}"
    mv "${tmp}" "${SETTINGS_FILE}"
    log "Set statusLine in ${SETTINGS_FILE} to: ${command}"
  else
    warn "Could not parse ${SETTINGS_FILE}; statusLine not set"
  fi
  rm -f "${tmp}"
}

# Only config.json is linked: ponytail keeps runtime data (band/) in the same dir.
# Changing the default level in ponytail writes through the link into the repo.
link_ponytail_config() {
  symlink_path "${CLAUDE_DOTFILES}/ponytail-config.json" \
    "${XDG_CONFIG_HOME:-${HOME}/.config}/ponytail/config.json"
}

# Each plugins.txt line: <plugin@marketplace> <marketplace GitHub repo>.
install_plugins() {
  local plugin repo installed markets

  if ! command -v claude >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
    warn "claude or jq not found; install them, then re-run $0 for plugins"
    return 0
  fi
  installed="$(claude plugin list --json </dev/null | jq -r '.[].id')"
  markets="$(claude plugin marketplace list --json </dev/null | jq -r '.[].repo // empty')"
  # </dev/null: claude must not eat the plugin list this loop reads from stdin.
  while read -r plugin repo; do
    if grep -qxF "${plugin}" <<<"${installed}"; then
      log "Plugin ${plugin} already installed"
      continue
    fi
    if ! grep -qxF "${repo}" <<<"${markets}"; then
      claude plugin marketplace add "${repo}" </dev/null || { warn "Could not add marketplace ${repo}"; continue; }
    fi
    if claude plugin install "${plugin}" </dev/null; then
      log "Installed plugin ${plugin}"
    else
      warn "Could not install plugin ${plugin}"
    fi
  done < <(read_package_file "${CLAUDE_DOTFILES}/plugins.txt")
}

main() {
  set_statusline
  link_ponytail_config
  install_plugins
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  main "$@"
fi

#!/usr/bin/env bash
set -euo pipefail

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT
CLAUDE_CONFIG_DIR="${tmp_dir}" source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/setup-claude.sh"
log() { :; }

printf '{"keep":true}\n' >"${SETTINGS_FILE}"
chmod 640 "${SETTINGS_FILE}"
set_statusline

[[ "$(jq -r '.keep' "${SETTINGS_FILE}")" == true ]]
[[ "$(jq -r '.statusLine.type' "${SETTINGS_FILE}")" == command ]]
[[ "$(stat -c %a "${SETTINGS_FILE}")" == 640 ]]

printf 'setup-claude tests passed\n'

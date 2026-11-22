#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

# Vim keys in Vesktop: Vencord built from source with the vimcord userplugin,
# because Vencord only runs plugins compiled into it. Re-run after editing
# dotfiles/.config/vesktop/vimcord, or to update Vencord.
# Vencord follows upstream, since an old build breaks when Discord updates.
# vimcord is our own copy (from github.com/RyanAHayden/vimcord at 6c4f10b): a
# plugin can reach the Discord login token, so upstream changes come in only
# after reading them.
VENCORD_DIR="${XDG_DATA_HOME:-${HOME}/.local/share}/vencord"
STATE_FILE="${XDG_CONFIG_HOME:-${HOME}/.config}/vesktop/state.json"

main() {
  require_arch
  pacman_install git npm

  if [[ -d ${VENCORD_DIR}/.git ]]; then
    git -C "${VENCORD_DIR}" pull --ff-only
  else
    git clone --depth 1 https://github.com/Vendicated/Vencord "${VENCORD_DIR}"
  fi

  # A copy, not a link: the build follows links back to this repo, where
  # Vencord's @api/@utils import paths don't resolve.
  local plugin="${VENCORD_DIR}/src/userplugins/vimcord"
  rm -rf -- "${plugin}"
  mkdir -p "${plugin%/*}"
  cp -r "${DOTFILES_DIR}/.config/vesktop/vimcord" "${plugin}"

  cd "${VENCORD_DIR}"
  # Vencord pins its pnpm version in package.json; npx runs that one, no global pnpm needed.
  local pnpm
  pnpm="$(node -p 'require("./package.json").packageManager')"
  npx -y "${pnpm}" install --frozen-lockfile
  npx -y "${pnpm}" build
  grep -q VimCord dist/vencordDesktopRenderer.js || die "vimcord is missing from the Vencord build"

  local dist="${VENCORD_DIR}/dist"
  if [[ $(node -p 'try { require(process.argv[1]).vencordDir } catch { "" }' "${STATE_FILE}") == "${dist}" ]]; then
    log "Vesktop already loads Vencord from ${dist}; restart Vesktop to use this build"
  elif pgrep -x vesktop >/dev/null; then
    # Vesktop rewrites state.json when it quits, so an edit made now would be lost.
    warn "Vesktop is open: pick ${dist} in Settings > Vesktop > Developer Options > Vencord Location, or close it and re-run"
  else
    mkdir -p "$(dirname "${STATE_FILE}")"
    node -e '
      const fs = require("fs");
      const [file, dir] = process.argv.slice(1);
      let state = {};
      try { state = JSON.parse(fs.readFileSync(file, "utf8")); } catch (e) { if (e.code !== "ENOENT") throw e; }
      state.vencordDir = dir;
      fs.writeFileSync(file, JSON.stringify(state, null, 4));
    ' "${STATE_FILE}" "${dist}"
    log "Vesktop loads Vencord from ${dist}"
  fi
  # Vencord's settings.json isn't in the repo (plugins can keep tokens there), so these are clicked once by hand
  log "Once, in Discord: Settings > Themes: turn on mr5obot-theme.css"
  log "Settings > Plugins: turn on VimCord, then in its settings: Hide servers on, Hide header off."
  log "Press ? in Discord for its keys"
}

main "$@"

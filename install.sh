#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/scripts/lib.sh"

run_step() {
  local label="$1"
  local script="$2"
  shift 2

  if prompt_step "${label}"; then
    log "Running ${script} $*"
    "${SCRIPT_DIR}/${script}" "$@"
  else
    log "Skipped ${label}"
  fi
}

main() {
  require_arch

  cat <<'EOF'
DotRobot Arch setup
Each step can be run, skipped, or revisited later.
EOF

  run_step "Configure pacman" "scripts/configure-pacman.sh"
  run_step "Install core packages" "scripts/install-packages.sh" core
  run_step "Install desktop packages" "scripts/install-packages.sh" desktop
  run_step "Install paru (AUR helper)" "scripts/setup-aur-helper.sh"
  run_step "Install AUR packages" "scripts/install-packages.sh" aur
  run_step "Link dotfiles into \$HOME" "scripts/link-dotfiles.sh"
  run_step "Install zinit and tmux TPM" "scripts/setup-shell-tools.sh"
  run_step "Set zsh as the default shell" "scripts/setup-zsh.sh"
  run_step "Set up git + ssh" "scripts/setup-git-ssh.sh"
  run_step "Create XDG user directories" "scripts/setup-user-dirs.sh"
  run_step "Apply Firefox theme" "scripts/apply-firefox-theme.sh"

  log "Setup finished. Log: ${LOG_FILE}"
}

main "$@"

#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

ZSHENV_FILE="/etc/zsh/zshenv"
ZSH_PACKAGES=(zsh neovim eza bat fd fzf zoxide starship ripgrep)

install_packages() {
  sudo pacman -S --needed --noconfirm "${ZSH_PACKAGES[@]}"
  log "Installed zsh and dependencies: ${ZSH_PACKAGES[*]}"
}

configure_zdotdir() {
  # zsh sources /etc/zsh/zshenv before any user rc file, so relocating ZDOTDIR
  # under XDG_CONFIG_HOME has to happen here to take effect on login.
  if [[ -f "${ZSHENV_FILE}" ]] && grep -q 'DotRobot: relocate zsh config' "${ZSHENV_FILE}"; then
    log "ZDOTDIR already configured in ${ZSHENV_FILE}"
    return 0
  fi

  sudo mkdir -p "$(dirname "${ZSHENV_FILE}")"
  sudo tee -a "${ZSHENV_FILE}" >/dev/null <<'EOF'

# DotRobot: relocate zsh config under XDG_CONFIG_HOME
if [[ -z "$XDG_CONFIG_HOME" ]]; then
    export XDG_CONFIG_HOME="$HOME/.config"
fi

if [[ -d "$XDG_CONFIG_HOME/zsh" ]]; then
    export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
fi
EOF
  log "Configured ZDOTDIR in ${ZSHENV_FILE}"
}

set_default_shell() {
  local zsh_path
  zsh_path="$(command -v zsh)"
  if [[ "${SHELL:-}" == "${zsh_path}" ]]; then
    log "Default shell is already zsh"
    return 0
  fi

  chsh -s "${zsh_path}"
  log "Changed default shell to ${zsh_path}"
}

main() {
  require_arch
  install_packages
  configure_zdotdir
  set_default_shell
}

main "$@"

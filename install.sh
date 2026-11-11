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
  [[ $EUID -eq 0 ]] && die "Run as your normal user; the installer uses sudo when needed."
  command -v sudo >/dev/null 2>&1 || die "sudo is required. Install it as root with: pacman -Syu sudo"
  sudo -v || die "Your user is not allowed to use sudo. Configure sudo first."
  # One full upgrade per run: the first package step syncs, later ones only add.
  DOTROBOT_SYNC_STAMP="$(mktemp -d)/synced"
  export DOTROBOT_SYNC_STAMP
  trap 'rm -rf -- "${DOTROBOT_SYNC_STAMP%/*}"' EXIT

  cat <<'EOF'
DotRobot Arch setup
Each step can be run, skipped, or revisited later.
EOF

  run_step "Replace /etc/pacman.conf with the tracked template (multilib on)" "scripts/configure-pacman.sh"
  run_step "Install core packages" "scripts/install-packages.sh" core
  run_step "Install desktop packages" "scripts/install-packages.sh" desktop
  run_step "Install paru (AUR helper)" "scripts/setup-aur-helper.sh"
  run_step "Install AUR packages" "scripts/install-packages.sh" aur
  run_step "Build wl-kbptr (SUPER+F keyboard clicking)" "scripts/setup-wl-kbptr.sh"
  run_step "Set up Flatpak + Flathub" "scripts/setup-flatpak.sh"
  run_step "Link dotfiles into \$HOME" "scripts/link-dotfiles.sh"
  run_step "Enable system services" "scripts/enable-services.sh"
  run_step "Set up SIM/mobile broadband (modem machines only)" "scripts/setup-mobile-broadband.sh"
  run_step "Set up zram sized for this machine" "scripts/setup-zram.sh"
  run_step "Show Windows in the GRUB menu (os-prober, dual boot only)" "scripts/setup-dual-boot.sh"
  run_step "Set up keyd key remapping" "scripts/setup-keyd.sh"
  run_step "Link browser video flags and enable Brovim on Helium browser pages" "scripts/setup-browser-flags.sh"
  run_step "Apply GTK/icon/cursor theme settings" "scripts/setup-gtk-theme.sh"
  run_step "Install zinit (zsh plugins)" "scripts/setup-shell-tools.sh"
  run_step "Set zsh as the default shell" "scripts/setup-zsh.sh"
  run_step "Set up git + ssh" "scripts/setup-git-ssh.sh"
  run_step "Set up login manager (ly or greetd + tuigreet)" "scripts/setup-login-manager.sh"
  run_step "Create XDG user directories" "scripts/setup-user-dirs.sh"
  # --yes: this prompt is the yes/no, so the script installs its plan without asking again.
  run_step "Install Steam + Proton (gaming)" "scripts/setup-steam.sh" --yes
  run_step "Set up fingerprint unlock (machines with a reader)" "scripts/setup-fingerprint.sh"
  run_step "Set up external monitor brightness control (ddcutil + i2c)" "scripts/setup-monitor-brightness.sh"
  log "Setup finished. Log: ${LOG_FILE}"
}

main "$@"

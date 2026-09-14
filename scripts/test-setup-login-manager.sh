#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/setup-login-manager.sh"
log() { :; }
warn() { :; }
disable_other_dms() { :; }
sudo() {
  case "$1" in
    pacman | systemctl) return ;;
    *) "$@" ;;
  esac
}

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT
GREETD_CONF="${tmp_dir}/config.toml"

printf 'original\n' >"${GREETD_CONF}"
setup_greetd
printf 'changed\n' >"${GREETD_CONF}"
setup_greetd

[[ "$(<"${GREETD_CONF}.dotrobot.bak")" == "original" ]]
grep -q '^command = "tuigreet ' "${GREETD_CONF}"

die() { return 1; }
rollback=0
sudo() {
  [[ "$*" == "systemctl enable old.service" ]] && rollback=1
  [[ "$*" != "systemctl enable new.service" ]]
}
DISABLED_DMS=(old.service)
! enable_dm new.service
(( rollback == 1 ))

printf 'setup-login-manager tests passed\n'

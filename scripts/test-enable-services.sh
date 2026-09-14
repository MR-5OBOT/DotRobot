#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_STATE="$(mktemp -d)"
trap 'rm -rf "${TEST_STATE}"' EXIT
export XDG_STATE_HOME="${TEST_STATE}"

source "${SCRIPT_DIR}/enable-services.sh"
require_arch() { :; }
systemctl() {
  [[ $1 == list-unit-files ]] || return 1
  printf '%s enabled\n' "$2"
}
sudo() { printf '%s\n' "$*" >> "${TEST_STATE}/actions"; }

printf 'n\ny\n' | main

actions="$(<"${TEST_STATE}/actions")"
[[ ${actions} == *'enable --now NetworkManager.service'* ]]
[[ ${actions} == *'enable --now power-profiles-daemon.service'* ]]
[[ ${actions} == *'enable --now thermald.service'* ]]
[[ ${actions} != *'bluetooth.service'* ]]
[[ ${actions} == *'enable --now docker.service'* ]]
printf 'enable-services opt-in test passed\n'

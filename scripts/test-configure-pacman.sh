#!/usr/bin/env bash
set -euo pipefail

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

HOME="$tmp/home" XDG_STATE_HOME="$tmp/state" source "$(dirname "$0")/configure-pacman.sh"
PACMAN_CONF="$tmp/pacman.conf"
TEMPLATE="$tmp/template"
require_arch() { :; }
prompt_step() { return 0; }
sudo() { "$@"; }

printf original >"$PACMAN_CONF"
printf first >"$TEMPLATE"
main
printf changed >"$PACMAN_CONF"
printf second >"$TEMPLATE"
main

[[ $(<"$PACMAN_CONF.dotrobot.bak") == original ]]
[[ $(<"$PACMAN_CONF") == second ]]
echo "configure-pacman backup test passed"

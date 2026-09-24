#!/usr/bin/env bash
set -euo pipefail

task_tmp=$(mktemp -d)
trap 'rm -rf -- "$task_tmp"' EXIT

# Source the real function without its install-time imports or main call.
sed '/^source /d; /^main "\$@"$/d' "$(dirname "$0")/setup-aur-helper.sh" > "$task_tmp/setup.sh"
source "$task_tmp/setup.sh"
require_arch() { :; }
log() { :; }
sudo() { :; }
git() { mkdir -p -- "$3"; }
makepkg() { :; }
command() {
  if [[ "${1:-}" == -v && "${2:-}" == paru ]]; then return 1; fi
  builtin command "$@"
}

TMPDIR="$task_tmp" main
[[ -z $(find "$task_tmp" -mindepth 1 ! -name setup.sh -print -quit) ]]

makepkg() { return 42; }
if TMPDIR="$task_tmp" main; then
  echo 'A failed build unexpectedly succeeded' >&2
  exit 1
fi
[[ -z $(find "$task_tmp" -mindepth 1 ! -name setup.sh -print -quit) ]]
echo 'Paru cleanup checks passed'

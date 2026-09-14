#!/usr/bin/env bash
set -euo pipefail

paru() {
  case "$1" in
    -Syu) [[ "$*" != *--noconfirm* ]] ;;
    -Qdtq) printf 'test-orphan\n' ;;
    -Rns) return 1 ;;
  esac
}
sudo() { :; }
export -f paru sudo

printf 'n\n' | bash "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/dotfiles/.local/bin/sysmaintenance" >/dev/null

printf 'sysmaintenance tests passed\n'

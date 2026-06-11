#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

main() {
  local git_name git_email key_path

  read -rp "Git user.name: " git_name
  read -rp "Git user.email: " git_email

  git config --global user.name "${git_name}"
  git config --global user.email "${git_email}"

  key_path="${HOME}/.ssh/id_ed25519"
  mkdir -p "${HOME}/.ssh"

  if [[ ! -f "${key_path}" ]]; then
    ssh-keygen -t ed25519 -C "${git_email}" -f "${key_path}" -N ""
  else
    log "SSH key already exists at ${key_path}"
  fi

  local ssh_config="${HOME}/.ssh/config"
  if [[ ! -f "${ssh_config}" ]] || ! grep -qiE '^[[:space:]]*Host[[:space:]]+github\.com([[:space:]]|$)' "${ssh_config}"; then
    cat >> "${ssh_config}" <<'EOF'
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519
  IdentitiesOnly yes
EOF
    log "Added github.com entry to ${ssh_config}"
  else
    log "github.com entry already present in ${ssh_config}"
  fi
  chmod 600 "${ssh_config}"

  if ! pgrep -u "${USER}" ssh-agent >/dev/null 2>&1; then
    eval "$(ssh-agent -s)" >/dev/null
  fi
  ssh-add "${key_path}" >/dev/null 2>&1 || true

  printf '\nPublic key:\n'
  cat "${key_path}.pub"
  printf '\n'

  ssh -T git@github.com || true
}

main "$@"

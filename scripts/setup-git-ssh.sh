#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

KEY_PATH="${HOME}/.ssh/id_ed25519"
LOCAL_GIT_CONFIG="${HOME}/.config/git/local.conf"

configure_git_identity() {
  local current_name current_email git_name git_email

  current_name="$(git config --global --get user.name || true)"
  current_email="$(git config --global --get user.email || true)"

  read -rp "Git user.name [${current_name}]: " git_name
  read -rp "Git user.email [${current_email}]: " git_email
  git_name="${git_name:-${current_name}}"
  git_email="${git_email:-${current_email}}"

  [[ -n "${git_name}" && -n "${git_email}" ]] || die "git user.name and user.email are both required."

  git config --file "${LOCAL_GIT_CONFIG}" user.name "${git_name}"
  git config --file "${LOCAL_GIT_CONFIG}" user.email "${git_email}"
  log "git identity: ${git_name} <${git_email}>"
}

ensure_key() {
  local ssh_dir
  ssh_dir="$(dirname "${KEY_PATH}")"

  mkdir -p "${ssh_dir}"
  chmod 700 "${ssh_dir}"

  if [[ -f "${KEY_PATH}" ]]; then
    log "SSH key already exists at ${KEY_PATH}"
  else
    ssh-keygen -t ed25519 -C "$(git config --global --get user.email)" -f "${KEY_PATH}"
    log "Generated ${KEY_PATH}"
  fi

  if [[ ! -s "${KEY_PATH}.pub" ]]; then
    printf '%s\n' "$(ssh-keygen -y -f "${KEY_PATH}")" >"${KEY_PATH}.pub"
    log "Rebuilt missing public key ${KEY_PATH}.pub"
  fi

  chmod 600 "${KEY_PATH}"
  chmod 644 "${KEY_PATH}.pub"
}

github_uses_key() {
  local option path ssh_config

  ssh_config="$(ssh -G github.com 2>/dev/null)" || return 1
  while read -r option path _; do
    [[ "${option}" == "identityfile" ]] || continue
    [[ "${path}" == "${KEY_PATH}" || "${path}" == "~/${KEY_PATH#"${HOME}/"}" ]] && return 0
  done <<<"${ssh_config}"
  return 1
}

ensure_ssh_config() {
  local ssh_config="${HOME}/.ssh/config"

  touch "${ssh_config}"
  chmod 600 "${ssh_config}"

  if grep -qiE '^[[:space:]]*Host[[:space:]]+github\.com([[:space:]]|$)' "${ssh_config}"; then
    if github_uses_key; then
      log "github.com already uses ${KEY_PATH}"
    else
      warn "Could not verify ${KEY_PATH} in the effective github.com SSH config."
      warn "If authentication fails, add 'IdentityFile ${KEY_PATH}' inside that Host block."
    fi
    return 0
  fi

  cat >>"${ssh_config}" <<EOF

Host github.com
  HostName github.com
  User git
  IdentityFile ${KEY_PATH}
  IdentitiesOnly yes
  AddKeysToAgent yes
EOF
  log "Added github.com entry to ${ssh_config}"
}

load_key_into_agent() {
  local status=0

  # ssh-add exits 2 when it cannot reach an agent at all, 1 when the agent is
  # simply empty.
  ssh-add -l >/dev/null 2>&1 || status=$?
  if ((status == 2)); then
    warn "No ssh-agent reachable; skipping ssh-add. SSH may prompt for the key passphrase when needed."
    return 0
  fi

  if ssh-add "${KEY_PATH}"; then
    log "Key loaded into the ssh-agent"
  else
    warn "Could not add ${KEY_PATH} to the ssh-agent"
  fi
}

github_auth_ok() {
  local output status=0

  output="$(ssh -o StrictHostKeyChecking=accept-new -T git@github.com 2>&1)" || status=$?
  # A working key makes github greet you by name and still exit 1, so match the
  # greeting rather than the exit status.
  [[ "${output}" == *"successfully authenticated"* ]]
}

ensure_gh() {
  if command -v gh >/dev/null 2>&1; then
    return 0
  fi
  log "Installing github-cli"
  sudo pacman -Syu --needed --noconfirm github-cli
}

gh_login() {
  if gh auth status --hostname github.com >/dev/null 2>&1; then
    log "gh is already authenticated"
    return 0
  fi

  printf '\nLogging in to GitHub. In a bare tty pick "Login with a web browser"\n'
  printf 'and type the one-time code at https://github.com/login/device\n\n'

  # admin:public_key up front so the upload below needs no second round trip;
  # the key is generated above, so gh should not offer to make another.
  gh auth login \
    --hostname github.com \
    --git-protocol ssh \
    --scopes admin:public_key \
    --skip-ssh-key
}

upload_key() {
  local title
  title="dotrobot-$(hostname)"

  if gh ssh-key add "${KEY_PATH}.pub" --title "${title}" --type authentication; then
    log "Uploaded ${KEY_PATH}.pub to GitHub as '${title}'"
  else
    warn "gh could not upload the key; it may already be registered"
  fi
}

authorize_key() {
  if github_auth_ok; then
    log "GitHub already accepts ${KEY_PATH}"
    return 0
  fi

  if ensure_gh && gh_login; then
    upload_key
    if github_auth_ok; then
      log "GitHub authentication succeeded"
      return 0
    fi
    warn "The key reached GitHub but authentication still fails."
  else
    warn "gh is unavailable; falling back to adding the key by hand."
  fi

  # Last resort: gh could not be installed, the login was aborted, or the
  # upload was refused.
  printf '\nAdd this key by hand at https://github.com/settings/ssh/new\n'
  printf 'Copy it, never retype it: one wrong character fails exactly like a missing key.\n\n'
  cat "${KEY_PATH}.pub"
  printf '\n'

  while true; do
    prompt_step "Added the key on GitHub? Check the connection now" || return 1
    if github_auth_ok; then
      log "GitHub authentication succeeded"
      return 0
    fi
    warn "GitHub still refuses the key."
  done
}

use_ssh_remote() {
  local url

  url="$(git -C "${REPO_ROOT}" remote get-url origin 2>/dev/null || true)"
  case "${url}" in
    git@github.com:*)
      log "origin already uses ssh"
      ;;
    https://github.com/*)
      git -C "${REPO_ROOT}" remote set-url origin "git@github.com:${url#https://github.com/}"
      log "origin now uses ssh: $(git -C "${REPO_ROOT}" remote get-url origin)"
      ;;
    "")
      warn "No origin remote found; skipping the remote rewrite"
      ;;
    *)
      warn "origin is ${url}; leaving it alone"
      ;;
  esac
}

github_owner() {
  local url

  url="$(git -C "${REPO_ROOT}" remote get-url origin 2>/dev/null || true)"
  case "${url}" in
    git@github.com:*/*) url="${url#git@github.com:}" ;;
    https://github.com/*/*) url="${url#https://github.com/}" ;;
    *) return 1 ;;
  esac
  printf '%s\n' "${url%%/*}"
}

prefer_ssh_for_own_repos() {
  local owner

  # Scoped to your own namespace on purpose: a blanket github.com rewrite would
  # push AUR builds and other third-party clones through your key too.
  if ! owner="$(github_owner)"; then
    warn "Could not read your GitHub owner from origin; skipping the insteadOf rule"
    return 0
  fi

  git config --file "${LOCAL_GIT_CONFIG}" "url.git@github.com:${owner}/.insteadOf" "https://github.com/${owner}/"
  log "https://github.com/${owner}/... will now clone over ssh"
}

main() {
  mkdir -p "$(dirname "${LOCAL_GIT_CONFIG}")"
  touch "${LOCAL_GIT_CONFIG}"

  configure_git_identity
  ensure_key
  ensure_ssh_config
  load_key_into_agent

  if authorize_key; then
    use_ssh_remote
    prefer_ssh_for_own_repos
  else
    warn "Skipped the ssh remote switch; run this script again once the key is on GitHub."
  fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi

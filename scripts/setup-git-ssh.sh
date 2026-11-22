#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

LOCAL_GIT_CONFIG="${HOME}/.config/git/local.conf"

configure_git_identity() {
  local current_name current_email git_name git_email

  current_name="$(git config --global --includes --get user.name || true)"
  current_email="$(git config --global --includes --get user.email || true)"

  read -rp "Git user.name [${current_name}]: " git_name
  read -rp "Git user.email [${current_email}]: " git_email
  git_name="${git_name:-${current_name}}"
  git_email="${git_email:-${current_email}}"

  [[ -n "${git_name}" && -n "${git_email}" ]] || die "git user.name and user.email are both required."

  git config --file "${LOCAL_GIT_CONFIG}" user.name "${git_name}"
  git config --file "${LOCAL_GIT_CONFIG}" user.email "${git_email}"
  log "git identity: ${git_name} <${git_email}>"
}

github_auth_ok() {
  local output status=0

  output="$(ssh -o StrictHostKeyChecking=accept-new -T git@github.com 2>&1)" || status=$?
  # A working key makes github greet you by name and still exit 1, so match the
  # greeting rather than the exit status.
  [[ "${output}" == *"successfully authenticated"* ]]
}

# gh's own login makes ~/.ssh/id_ed25519 when there is none and uploads it.
authorize_key() {
  if github_auth_ok; then
    log "GitHub already accepts your SSH key"
    return 0
  fi

  pacman_install github-cli || return 1
  if gh auth status --hostname github.com >/dev/null 2>&1; then
    warn "gh is logged in, but GitHub refuses your SSH key. Upload it, then re-run:"
    warn "  gh auth refresh -s admin:public_key && gh ssh-key add ~/.ssh/id_ed25519.pub"
    return 1
  fi

  printf '\nLogging in to GitHub: answer yes to the SSH key question. In a bare tty pick\n'
  printf '"Login with a web browser" and type the one-time code at https://github.com/login/device\n\n'
  gh auth login --hostname github.com --git-protocol ssh || return 1
  github_auth_ok
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

  if authorize_key; then
    use_ssh_remote
    prefer_ssh_for_own_repos
  else
    warn "Skipped the ssh remote switch; run this script again once the key is on GitHub."
  fi
}

main "$@"

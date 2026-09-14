#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/setup-git-ssh.sh"
log() { :; }

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT
LOCAL_GIT_CONFIG="${tmp_dir}/local.conf"
touch "${LOCAL_GIT_CONFIG}"

configure_git_identity <<< $'Test User\ntest@example.com'
github_owner() { printf 'TestOwner\n'; }
prefer_ssh_for_own_repos

[[ "$(git config --file "${LOCAL_GIT_CONFIG}" user.name)" == "Test User" ]]
[[ "$(git config --file "${LOCAL_GIT_CONFIG}" user.email)" == "test@example.com" ]]
[[ "$(git config --file "${LOCAL_GIT_CONFIG}" --get 'url.git@github.com:TestOwner/.insteadOf')" == "https://github.com/TestOwner/" ]]

KEY_PATH="${tmp_dir}/ssh/id_ed25519"
mkdir -p "$(dirname "${KEY_PATH}")"
ssh-keygen -q -t ed25519 -N '' -f "${KEY_PATH}"
rm "${KEY_PATH}.pub"
ensure_key
ssh-keygen -l -f "${KEY_PATH}.pub" >/dev/null

ssh() { printf 'identityfile %s\n' "${KEY_PATH}"; }
github_uses_key
ssh() { printf 'identityfile /tmp/a-different-key\n'; }
! github_uses_key

printf 'setup-git-ssh tests passed\n'

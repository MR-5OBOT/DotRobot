#!/usr/bin/env bash
set -euo pipefail

task_tmp=$(mktemp -d)
trap 'rm -rf -- "$task_tmp"' EXIT
mkdir -p "$task_tmp/bin" "$task_tmp/cache" "$task_tmp/first root" "$task_tmp/second root"

cat > "$task_tmp/bin/fd" <<'EOF'
#!/bin/sh
for root do :; done
if [ "${FD_SLOW:-}" = 1 ]; then
  printf '%s\n' "$root/new-one"
  sleep 0.4
  printf '%s\n' "$root/new-two"
else
  printf '%s\n%s\n' "$root/original-one" "$root/original-two"
fi
EOF
cat > "$task_tmp/bin/fzf" <<'EOF'
#!/bin/sh
cat > "$FZF_INPUT"
EOF
chmod +x "$task_tmp/bin/fd" "$task_tmp/bin/fzf"

export PATH="$task_tmp/bin:$PATH" XDG_CACHE_HOME="$task_tmp/cache" FZF_INPUT="$task_tmp/choices"
function_file="$(dirname "$0")/../dotfiles/.config/zsh/conf.d/functions.zsh"
zsh -fc 'source "$1"; f "$2" || :' _ "$function_file" "$task_tmp/first root"

for attempt in {1..20}; do
  cache_file=$(find "$task_tmp/cache" -maxdepth 1 -type f -name 'fzf-dirs-*' -print -quit)
  [[ -n "$cache_file" ]] && break
  sleep 0.05
done
[[ -n "$cache_file" ]]
printf '%s\n%s\n' "$task_tmp/first root/original-one" "$task_tmp/first root/original-two" > "$task_tmp/expected"
cmp -s "$cache_file" "$task_tmp/expected"

zsh -fc 'source "$1"; f "$2" || :' _ "$function_file" "$task_tmp/second root"
[[ $(cat "$task_tmp/choices") == *"second root"* ]]
[[ $(cat "$task_tmp/choices") != *"first root"* ]]

touch -d '10 minutes ago' "$cache_file"
FD_SLOW=1 zsh -fc 'source "$1"; f "$2" || :' _ "$function_file" "$task_tmp/first root"
cmp -s "$task_tmp/choices" "$task_tmp/expected"
sleep 0.6
printf '%s\n%s\n' "$task_tmp/first root/new-one" "$task_tmp/first root/new-two" > "$task_tmp/expected"
cmp -s "$cache_file" "$task_tmp/expected"
[[ -z $(find "$task_tmp/cache" -name 'fzf-dirs-*.??????' -print -quit) ]]
echo 'f() cache checks passed'

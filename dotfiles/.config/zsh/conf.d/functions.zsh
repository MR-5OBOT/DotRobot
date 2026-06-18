# Shell functions.

# Fuzzy-cd into a directory under $1 (defaults to $HOME).
f() {
  local dir
  dir=$(fd --type d --hidden --exclude .git . "${1:-$HOME}" | fzf \
    --preview 'eza --tree --level=2 --icons --color=always {} | head -20')
  [[ -n "$dir" ]] && cd "$dir"
}

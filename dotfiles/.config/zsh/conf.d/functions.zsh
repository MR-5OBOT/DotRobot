# Shell functions.

# Fuzzy-cd into a directory under $1 (defaults to $HOME).
f() {
  local dir root="${1:-$HOME}"
  local cache="${XDG_CACHE_HOME:-$HOME/.cache}/fzf-dirs"

  # Refresh cache in background if >5min stale
  if [[ ! -f "$cache" || -n "$(find "$cache" -mmin +5 2>/dev/null)" ]]; then
    fd --type d --hidden --exclude .git --max-depth 8 . "$root" >| "$cache" &!
  fi

  dir=$(
    { [[ -f "$cache" ]] && cat "$cache" \
        || fd --type d --hidden --exclude .git . "$root"; } \
    | fzf \
        --preview 'eza -1 --icons --color=always {} 2>/dev/null | head -30' \
        --preview-window=right:35%
  )

  [[ -n "$dir" ]] && cd "$dir"
}

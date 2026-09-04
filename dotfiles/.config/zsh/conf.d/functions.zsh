# Shell functions.

# Fuzzy-cd into a directory under $1 (defaults to $HOME).
f() {
  local dir root="${1:-$HOME}"
  local cache="${XDG_CACHE_HOME:-$HOME/.cache}/fzf-dirs"

  # Skip noisy dirs; keep useful ones like .config and .local.
  local -a ex
  local d
  for d in .git .cache node_modules .cargo .rustup .npm .nvm .mozilla \
           .var __pycache__ .venv venv .local/share/Trash .local/share/Steam \
           .gradle .m2 go/pkg .android .vscode-oss; do
    ex+=(--exclude "$d")
  done

  # Refresh cache in background if >5min stale
  if [[ ! -f "$cache" || -n "$(find "$cache" -mmin +5 2>/dev/null)" ]]; then
    fd --type d --hidden $ex --max-depth 8 . "$root" >| "$cache" &!
  fi

  dir=$(
    { [[ -s "$cache" ]] && cat "$cache" \
        || fd --type d --hidden $ex --max-depth 8 . "$root"; } \
    | fzf \
        --height=30% \
        --margin=0,25% \
        --preview 'eza -1 --icons --color=always {} 2>/dev/null | head -30' \
        --preview-window=right:35%
  )

  [[ -n "$dir" ]] && cd "$dir"
}

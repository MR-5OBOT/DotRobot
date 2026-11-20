# Shell functions.

# Fuzzy-cd into a directory under $1 (defaults to $HOME).
f() {
  local dir root="${1:-$HOME}"
  root="${root:A}"
  local cache="${XDG_CACHE_HOME:-$HOME/.cache}/fzf-dirs-$(printf '%s' "$root" | sha256sum | cut -d' ' -f1)"
  mkdir -p -- "${cache:h}" || return 1

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
    (
      tmp=$(mktemp "${cache}.XXXXXX") || exit
      trap 'rm -f -- "$tmp"' EXIT
      fd --type d --hidden "${ex[@]}" --max-depth 8 . "$root" > "$tmp" && mv -f -- "$tmp" "$cache"
    ) &!
  fi

  dir=$(
    { [[ -s "$cache" ]] && cat "$cache" \
        || fd --type d --hidden "${ex[@]}" --max-depth 8 . "$root"; } \
    | fzf \
        --height=30% \
        --margin=0,25% \
        --preview 'eza -1 --icons --color=always {} 2>/dev/null | head -30' \
        --preview-window=right:35%
  )

  [[ -n "$dir" ]] && cd "$dir"
}

# Window title = what's running, like tmux's automatic-rename; kitty's tab bar shows it
# (kitty/workflow.conf). "zsh" at the prompt, the command's first word while it runs.
# Kitty's shell integration (.zshrc) has its titles off (no-title in kitty.conf): they'd be
# the folder / whole command line.
autoload -Uz add-zsh-hook
_title_prompt() { print -nr -- $'\e]2;zsh\a'; }
_title_cmd() { local -a w=(${(z)1}); print -nr -- $'\e]2;'"${(V)w[1]:t}"$'\a'; }
add-zsh-hook precmd _title_prompt
add-zsh-hook preexec _title_cmd

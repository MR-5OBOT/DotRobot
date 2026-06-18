# ~/.config/zsh/.zshenv
# Sourced for every shell (login, interactive, scripts). Environment only —
# no aliases, functions, prompt, or interactive setup (that lives in .zshrc).

# ---------- XDG base directories ----------
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

# ---------- Editor ----------
export EDITOR="nvim"
export VISUAL="nvim"

# ---------- Pager ----------
if command -v bat >/dev/null 2>&1; then
  export MANPAGER="bat -l man -p"
elif command -v batcat >/dev/null 2>&1; then
  export MANPAGER="batcat -l man -p"
fi

# ---------- fzf ----------
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --inline-info"

# ---------- GPG ----------
export GPG_TTY="$(tty)"

# ---------- Starship ----------
export STARSHIP_CONFIG="${ZDOTDIR:-$HOME/.config/zsh}/starship.toml"

# ---------- PATH ----------
# `path` is tied to PATH; `typeset -U` keeps it free of duplicates.
typeset -U path
path=(
  "$HOME/.local/bin"
  "$HOME/bin"
  "$HOME/.npm-global/bin"
  "$HOME/.cargo/bin"
  $path
)
export PATH

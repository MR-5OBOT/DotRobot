# Plugin manager (zinit), tool integrations, and prompt.

# Set before zsh-autosuggestions loads.
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=60"

# Keep the completion dump in the cache dir, not $ZDOTDIR (which is the repo).
ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-${ZSH_VERSION}"
mkdir -p "${ZSH_COMPDUMP:h}"

# ---------- zinit + plugins ----------
if [[ -r "$ZINIT_HOME/zinit.zsh" ]]; then
  source "$ZINIT_HOME/zinit.zsh"
  zinit light zsh-users/zsh-completions
  zinit wait lucid for \
    atload"autoload -Uz compinit; compinit -d '$ZSH_COMPDUMP'; zicdreplay" \
    aloxaf/fzf-tab \
    zsh-users/zsh-autosuggestions \
    zdharma-continuum/fast-syntax-highlighting
else
  autoload -Uz compinit && compinit -d "$ZSH_COMPDUMP"
  print -P "%F{yellow}zinit not installed. Run scripts/setup-shell-tools.sh for plugin bootstrap.%f"
fi

# ---------- zoxide (smarter cd) ----------
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

# ---------- Starship prompt ----------
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"

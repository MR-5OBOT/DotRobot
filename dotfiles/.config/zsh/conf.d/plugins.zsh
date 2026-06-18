# Plugin manager (zinit), tool integrations, and prompt.

# Set before zsh-autosuggestions loads.
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=60"

# ---------- zinit + plugins ----------
if [[ -r "$ZINIT_HOME/zinit.zsh" ]]; then
  source "$ZINIT_HOME/zinit.zsh"
  zinit light zsh-users/zsh-completions
  zinit wait lucid for \
    atload"zicompinit; zicdreplay" \
    aloxaf/fzf-tab \
    zsh-users/zsh-autosuggestions \
    zdharma-continuum/fast-syntax-highlighting
else
  autoload -Uz compinit && compinit
  print -P "%F{yellow}zinit not installed. Run scripts/setup-shell-tools.sh for plugin bootstrap.%f"
fi

# ---------- zoxide (smarter cd) ----------
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

# ---------- Starship prompt ----------
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"

# --- 1. Environment & Paths ---
export ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
export HISTFILE=~/.zsh_history
export HISTSIZE=100000   # A bit larger history — why not?
export SAVEHIST=100000
export EDITOR='nvim'

alias nf='neofetch'

# Add user bin folders to PATH
if [[ -d "$HOME/bin" ]]; then export PATH="$HOME/bin:$PATH"; fi
if [[ -d "$HOME/.local/bin" ]]; then export PATH="$HOME/.local/bin:$PATH"; fi
export PATH=$HOME/.npm-global/bin:$PATH

# FZF Layout Options (Dracula-ish styling)
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --inline-info'

# --- 2. Zinit Bootstrap ---
if [[ ! -d $ZINIT_HOME ]]; then
    mkdir -p "$(dirname $ZINIT_HOME)"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"

# --- 3. Prompt & Core Plugins ---
zinit light zsh-users/zsh-completions
eval "$(starship init zsh)"

# --- 4. Zsh Options (The Fixes) ---
setopt AUTO_CD
setopt HIST_IGNORE_ALL_DUPS
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY

setopt AUTO_MENU
setopt COMPLETE_IN_WORD
setopt ALWAYS_TO_END
setopt COMPLETE_ALIASES

# --- 5. The "Preview Everything" Configuration ---
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' 'r:|[._-]=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# FZF-TAB PREVIEW SETTINGS
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':completion:*' menu no

zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' fzf-preview 'echo ${(P)word}'
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"
zstyle ':fzf-tab:complete:*:*' fzf-preview 'less ${(Q)realpath}'
zstyle ':fzf-tab:complete:kill:argument-rest' fzf-preview 'ps --pid=$word -o cmd --no-headers -w -w'
zstyle ':fzf-tab:complete:git-(checkout|switch|branch):*' fzf-preview \
  'git log --oneline --graph --date=short --color=always --pretty="format:%C(auto)%cd %h%d %s" $word'

if command -v bat > /dev/null; then
  zstyle ':fzf-tab:complete:*:*' fzf-preview 'bat --color=always --style=numbers --line-range=:500 {}'
else
  zstyle ':fzf-tab:complete:*:*' fzf-preview 'cat {}'
fi

zstyle ':fzf-tab:*' switch-group '<' '>'

# --- 6. Turbo Loaded Plugins ---
zinit wait lucid for \
    atload"zicompinit; zicdreplay" \
    aloxaf/fzf-tab \
    zsh-users/zsh-autosuggestions \
    zdharma-continuum/fast-syntax-highlighting

export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=60'

# --- 7. Aliases ---
alias v='nvim'
alias mv='mv -i'
alias lg='lazygit'
alias rm='trash -v'
alias mkdir='mkdir -p -v'
alias ..="cd .."
alias ...="cd ../../"
alias ls='eza -a --icons'
alias l="ls -lah"
alias c="clear"
alias lt="eza --tree --level=2 --long --icons --git -la"
alias vzshrc='nvim ~/.zshrc'
alias szshrc='source ~/.zshrc'
alias goo='start-hyprland'

# --- 8. Functions ---
f() {
    local dir
    dir=$(fd --type d --hidden --exclude .git . "${1:-$HOME}" | fzf \
      --preview 'eza --tree --level=2 --icons --color=always {} | head -20')
    [[ -n "$dir" ]] && cd "$dir"
}

# Keybindings
bindkey '^ ' autosuggest-accept
bindkey '^[[C' forward-word


# Auto-install TPM (Tmux Plugin Manager) if not installed
if [[ ! -d ~/.tmux/plugins/tpm ]]; then
  echo "Installing TPM (Tmux Plugin Manager)..."
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  echo "TPM installed successfully!"
fi


# --- 1. Environment & Paths ---
export ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
export HISTFILE=~/.zsh_history
export HISTSIZE=10000
export SAVEHIST=10000
export EDITOR='nvim'

neofetch

# [FIX] Add user bin folders to PATH so you can run scripts from anywhere
if [[ -d "$HOME/bin" ]]; then export PATH="$HOME/bin:$PATH"; fi
if [[ -d "$HOME/.local/bin" ]]; then export PATH="$HOME/.local/bin:$PATH"; fi

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
# [FIX] AUTO_CD: Type 'Downloads' instead of 'cd Downloads'
setopt AUTO_CD              

# History Options
setopt HIST_IGNORE_ALL_DUPS  # Don't record dupes in history
setopt SHARE_HISTORY         # Share history between terminals
setopt INC_APPEND_HISTORY    # Write to history immediately

# Completion Options
autoload -Uz compinit
compinit -C
setopt AUTO_MENU
setopt COMPLETE_IN_WORD
setopt ALWAYS_TO_END
setopt COMPLETE_ALIASES

# --- 5. The "Preview Everything" Configuration ---
# Matcher: Case insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' 'r:|[._-]=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# --- FZF-TAB PREVIEW SETTINGS ---
# Disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false

# Force zsh not to show completion menu, just use fzf
zstyle ':completion:*' menu no

# 1. Preview Directory (using eza)
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'

# 2. Preview Environment Variables (export/unset)
zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' \
	fzf-preview 'echo ${(P)word}'

# 3. Preview System Processes (kill) - Shows full command for the PID
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"
zstyle ':fzf-tab:complete:*:*' fzf-preview 'less ${(Q)realpath}'
zstyle ':fzf-tab:complete:kill:argument-rest' fzf-preview \
  'ps --pid=$word -o cmd --no-headers -w -w'

# 4. Preview Git Branches/Log
zstyle ':fzf-tab:complete:git-(checkout|switch|branch):*' fzf-preview \
	'git log --oneline --graph --date=short --color=always --pretty="format:%C(auto)%cd %h%d %s" $word'

# 5. Preview File Contents (using bat if available, else cat)
# This covers nvim, cat, less, and generic commands
if command -v bat > /dev/null; then
  zstyle ':fzf-tab:complete:*:*' fzf-preview 'bat --color=always --style=numbers --line-range=:500 {}'
else
  zstyle ':fzf-tab:complete:*:*' fzf-preview 'cat {}'
fi

# Switch group using `<` and `>`
zstyle ':fzf-tab:*' switch-group '<' '>'

# --- 6. Turbo Loaded Plugins ---
zinit wait lucid for \
    atload"zicompinit; zicdreplay" \
    aloxaf/fzf-tab \
    zsh-users/zsh-autosuggestions \
    zdharma-continuum/fast-syntax-highlighting

# Grey out autosuggestions
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=60'

# --- 7. Aliases ---
alias v='nvim'
alias mv='mv -i'
alias lg='lazygit'
alias rm='trash -v'         # Requires trash-cli
alias mkdir='mkdir -p -v'
alias ..="cd .."
alias ...="cd ../../"
alias ls='eza -a --icons'
alias l="ls -lah"
alias c="clear"
alias lt="eza --tree --level=2 --long --icons --git -la"
alias vzshrc='nvim ~/.zshrc'
alias szshrc='source ~/.zshrc'

# --- 8. Functions ---

# Better "f" - Fuzzy find dir and enter it
f() {
    local dir
    dir=$(fd --type d --hidden --exclude .git . "${1:-$HOME}" | fzf \
      --preview 'eza --tree --level=2 --icons --color=always {} | head -20')
    [[ -n "$dir" ]] && cd "$dir"
}

# Keybindings
bindkey '^ ' autosuggest-accept
bindkey '^[[C' forward-word


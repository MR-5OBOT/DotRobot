export ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
export HISTFILE="${HOME}/.zsh_history"
export HISTSIZE=100000
export SAVEHIST=100000
export EDITOR="nvim"
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --inline-info"

[[ -d "${HOME}/bin" ]] && export PATH="${HOME}/bin:${PATH}"
[[ -d "${HOME}/.local/bin" ]] && export PATH="${HOME}/.local/bin:${PATH}"
export PATH="${HOME}/.npm-global/bin:${PATH}"

alias nf="fastfetch"
alias v="nvim"
alias mv="mv -i"
alias lg="lazygit"
alias rm="trash -v"
alias mkdir="mkdir -p -v"
alias ..="cd .."
alias ...="cd ../../"
alias ls="eza -a --icons"
alias l="ls -lah"
alias c="clear"
alias lt="eza --tree --level=2 --long --icons --git -la"
alias vzshrc="nvim ~/.zshrc"
alias szshrc="source ~/.zshrc"
alias goo="start-hyprland"

setopt AUTO_CD
setopt HIST_IGNORE_ALL_DUPS
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY
setopt AUTO_MENU
setopt COMPLETE_IN_WORD
setopt ALWAYS_TO_END
setopt COMPLETE_ALIASES

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' 'r:|[._-]=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':completion:*' menu no
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' fzf-preview 'echo ${(P)word}'
zstyle ':fzf-tab:complete:kill:argument-rest' fzf-preview 'ps --pid=$word -o cmd --no-headers -w -w'
zstyle ':fzf-tab:complete:git-(checkout|switch|branch):*' fzf-preview \
  'git log --oneline --graph --date=short --color=always --pretty="format:%C(auto)%cd %h%d %s" $word'

if command -v bat >/dev/null 2>&1; then
  zstyle ':fzf-tab:complete:*:*' fzf-preview 'bat --color=always --style=numbers --line-range=:500 {}'
else
  zstyle ':fzf-tab:complete:*:*' fzf-preview 'cat {}'
fi

zstyle ':fzf-tab:*' switch-group '<' '>'

if [[ -r "${ZINIT_HOME}/zinit.zsh" ]]; then
  source "${ZINIT_HOME}/zinit.zsh"
  zinit light zsh-users/zsh-completions
  zinit wait lucid for \
    atload"zicompinit; zicdreplay" \
    aloxaf/fzf-tab \
    zsh-users/zsh-autosuggestions \
    zdharma-continuum/fast-syntax-highlighting
else
  print -P "%F{yellow}zinit is not installed. Run scripts/setup-shell-tools.sh if you want plugin bootstrap.%f"
fi

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=60"

f() {
  local dir
  dir=$(fd --type d --hidden --exclude .git . "${1:-$HOME}" | fzf \
    --preview 'eza --tree --level=2 --icons --color=always {} | head -20')
  [[ -n "$dir" ]] && cd "$dir"
}

bindkey '^ ' autosuggest-accept
bindkey '^[[C' forward-word

bindkey -v
export KEYTIMEOUT=1
bindkey -M viins '^?' backward-delete-char
bindkey -M viins '^H' backward-delete-char

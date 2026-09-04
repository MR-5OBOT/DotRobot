# Completion styling. Loaded before plugins.zsh so the styles are in place
# when zinit/fzf-tab run compinit.

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' 'r:|[._-]=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"

# ---------- fzf-tab previews ----------
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

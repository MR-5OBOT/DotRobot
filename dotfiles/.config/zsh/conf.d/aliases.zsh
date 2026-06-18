# Shell aliases.

# ---------- Editor / tools ----------
alias v="nvim"
alias ff="fastfetch"
alias lg="lazygit"
alias c="clear"

# ---------- Safety nets ----------
alias mv="mv -i"
alias rm="trash -v"
alias mkdir="mkdir -p -v"

# ---------- Navigation ----------
alias ..="cd .."
alias ...="cd ../../"

# ---------- eza (ls replacement) ----------
alias ls="eza -a --icons"
alias l="eza -lah --icons"
alias lt="eza --tree --level=2 --long --icons --git -la"

# ---------- zsh config ----------
alias vzshrc="nvim ${ZDOTDIR:-$HOME/.config/zsh}/.zshrc"
alias szshrc="source ${ZDOTDIR:-$HOME/.config/zsh}/.zshrc"

# ---------- Misc ----------
alias goo="start-hyprland"
alias quick-wifi-scan='sudo nmcli dev wifi rescan && nmcli dev wifi list'

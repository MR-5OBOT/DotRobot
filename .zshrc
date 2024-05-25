# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# START STARSHIP
eval "$(starship init zsh)"

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Add in snippets
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::archlinux
zinit snippet OMZP::aws
zinit snippet OMZP::kubectl
zinit snippet OMZP::kubectx
zinit snippet OMZP::command-not-found

# Load completions
autoload -Uz compinit && compinit
zinit cdreplay -q

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Set up the PATH
export PATH="$HOME/.local/bin:$PATH"

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# ALIASES
alias ff='fd --type f --hidden --exclude .git | fzf-tmux --preview "bat {}" -p --reverse | xargs -o sh -c '\''[ -z "$1" ] || nvim "$1"'\'' sh' # find & open files in nvim

alias flist='kitty list-fonts | fzf'
alias lg='lazygit'
alias v='nvim'
alias free='free -h'
alias c='clear'
alias mv='mv -i'
alias rm='trash -v'
alias mkdir='mkdir -p -v'
#cd aliases
alias ..="cd .."
alias ...="cd ../../"
# Eza & ls
alias la='ls -Alh' # show hidden files
alias ls='eza -a --icons'
alias l="eza -l --icons --git -a"
alias lt="eza --tree --level=2 --long --icons --git"

# CD TO REPOS
alias dlab='cd ~/repos/Dev-Lab/'
alias vlab='v ~/repos/MR-NV/nvim/'
alias tj='cd ~/repos/Dev-Lab/latex-projects/trading-journal/'
alias .dots='cd ~/repos/DotRoboT/'

# EDIT CONFIG FILES
alias vbashrc='$EDITOR ~/.bashrc'
alias vzshrc='$EDITOR ~/.zshrc'

# IP address lookup
myip ()
     {
ip addr show | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*'
}


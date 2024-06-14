# Set the directory to store Zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit if not present
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load Zinit
source "${ZINIT_HOME}/zinit.zsh"

# Start Starship
eval "$(starship init zsh)"

# start Zoxide
eval "$(zoxide init zsh)"

# Add Zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light aloxaf/fzf-tab

# Load completions
autoload -Uz compinit && compinit
zinit cdreplay -q

# History settings
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
zstyle ':completion:*' menu no

# Aliases
alias ff='fd --type f --hidden --exclude .git | fzf-tmux --preview "bat {}" -p --reverse | xargs -o sh -c '\''[ -z "$1" ] || nvim "$1"'\'' sh' # find & open files in nvim
alias v='nvim'
alias c='clear'
alias mv='mv -i'
alias lg='lazygit'
alias rm='trash -v'
alias mkdir='mkdir -p -v'
alias ..="cd .."
alias ...="cd ../../"
alias ls='eza -a --icons'
alias l="eza -l --icons --git -a"
alias lt="eza --tree --level=2 --long --icons --git"

# CD to repos
alias dlab='cd ~/repos/Dev-Lab/'
alias vlab='v ~/repos/MR-NV/nvim/'
alias tj='cd ~/repos/Dev-Lab/latex-projects/trading-journal/'
alias .dots='cd ~/repos/DotRoboT/'

# Edit config files
alias vbashrc='$EDITOR ~/.bashrc'
alias vzshrc='$EDITOR ~/.zshrc'

# IP address lookup function
myip() {
    ip addr show | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*'
}


# snapd Path apps
export XDG_DATA_DIRS="$XDG_DATA_DIRS:/var/lib/snapd/desktop"


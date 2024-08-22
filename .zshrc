
# Set the directory to store Zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit if not present
if [ ! -d "$ZINIT_HOME" ]; then
    mkdir -p "$(dirname "$ZINIT_HOME")"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load Zinit
if [ -f "${ZINIT_HOME}/zinit.zsh" ]; then
    source "${ZINIT_HOME}/zinit.zsh"
else
    echo "Error: zinit.zsh not found in ${ZINIT_HOME}. Please check the installation."
fi

export VISUAL="${EDITOR}"
export EDITOR='neovim'
export HISTORY_IGNORE="(ls|cd|pwd|exit|sudo reboot|history|cd -|cd ..)"
export SUDO_PROMPT="Deploying root access for %u. Password pls: "

# Set up the PATH
if [ -d "$HOME/.local/bin" ] ;
  then PATH="$HOME/.local/bin:$PATH"
fi

# Initialize Starship prompt
eval "$(starship init zsh)"

# Initialize Zoxide
eval "$(zoxide init zsh)"

# Add Zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light aloxaf/fzf-tab

# Load completions
autoload -Uz compinit && compinit
zinit cdreplay -q

#  ┬ ┬┬┌─┐┌┬┐┌─┐┬─┐┬ ┬
#  ├─┤│└─┐ │ │ │├┬┘└┬┘
#  ┴ ┴┴└─┘ ┴ └─┘┴└─ ┴ 
HISTFILE=~/.config/zsh/zhistory
HISTFILE=~/.zsh_history
HISTSIZE=5000
SAVEHIST=5000
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

#  ┌─┐┌─┐┬ ┬  ┌─┐┌─┐┌─┐┬    ┌─┐┌─┐┌┬┐┬┌─┐┌┐┌┌─┐
#  ┌─┘└─┐├─┤  │  │ ││ ││    │ │├─┘ │ ││ ││││└─┐
#  └─┘└─┘┴ ┴  └─┘└─┘└─┘┴─┘  └─┘┴   ┴ ┴└─┘┘└┘└─┘
setopt AUTOCD              # change directory just by typing its name
setopt PROMPT_SUBST        # enable command substitution in prompt
setopt MENU_COMPLETE       # Automatically highlight first element of completion menu
setopt LIST_PACKED		   # The completion menu takes less space.
setopt AUTO_LIST           # Automatically list choices on ambiguous completion.
setopt COMPLETE_IN_WORD    # Complete from both ends of a word.

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' menu no

# Aliases
alias ff='fd --type f --hidden --exclude .git | fzf --preview "bat {}" --reverse | xargs -x sh -c '"'"'[ -z "$1" ] || nvim "$1"'"'"' sh'
alias v='nvim'
alias c='clear'
alias mv='mv -i'
alias lg='lazygit'
alias rm='trash -v'
alias mkdir='mkdir -p -v'
alias ..="cd .."
alias ...="cd ../../"
alias ls='eza -a --icons'
alias l="ls -lah"
alias lt="eza --tree --level=2 --long --icons --git"

# CD to repos
alias mlab='cd ~/repos/The-Lab/'
alias vlab='v ~/repos/DotRoboT/.config/nvim/'
alias tlab='cd ~/repos/Dev-Lab/latex-projects/trading-journal/'
alias .dots='cd ~/repos/DotRoboT/'

# Edit config files
alias vbashrc='nvim ~/.bashrc'
alias vzshrc='nvim ~/.zshrc'

# update the dotfiles
alias fixdotfiles='sh ~/repos/DotRoboT/.setup/MR5OBOT-dotfiles-setup.sh'

# IP address lookup function
myip() {
    ip addr show | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*'
}

# colors for the man pages
export LESS='-R --use-color -Dd+r$Du+b$'

# snapd PATH
export PATH="/var/lib/snapd/snap/bin:$PATH"


# Set the directory to store Zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit if not present
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname "$ZINIT_HOME")"
   echo "Downloading Zinit..."
   git clone https://github.com/zdharma/zinit.git "$ZINIT_HOME" || { echo "Failed to clone Zinit"; exit 1; }
fi

export PATH="$HOME/.local/bin:$PATH"

# Source/Load Zinit
source "${ZINIT_HOME}/zinit.zsh"

# Initialize Starship prompt
eval "$(starship init zsh)"

# Initialize Zoxide
eval "$(zoxide init zsh)"

# Add Zsh plugins
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light aloxaf/fzf-tab

# Load completions
autoload -Uz compinit && compinit
zinit cdreplay -q

# History file configuration
HISTFILE=~/.zsh_history
HISTSIZE=100
SAVEHIST=100

setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion options
setopt AUTOCD              # change directory just by typing its name
setopt PROMPT_SUBST        # enable command substitution in prompt
setopt MENU_COMPLETE       # Automatically highlight first element of completion menu
setopt LIST_PACKED	   	   # The completion menu takes less space.
setopt AUTO_LIST           # Automatically list choices on ambiguous completion.
setopt COMPLETE_IN_WORD    # Complete from both ends of a word.

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' menu no

# Aliases
alias ff='fd --type f --hidden --exclude .git | fzf --preview "bat {}" --reverse | xargs -x sh -c '"'"'[ -z "$1" ] || nvim "$1"'"'"' sh'
alias v='nvim'
alias mv='mv -i'
alias lg='lazygit'
alias rm='trash -v'
alias mkdir='mkdir -p -v'
alias ..="cd .."
alias ...="cd ../../"
alias ls='eza -a --icons'  # Ensure eza is installed
alias l="ls -lah"
alias lt="eza --tree --level=2 --long --icons --git"

# CD to repos
alias codelab='cd ~/repos/Code-Lab/'
alias nvlab='cd ~/repos/DotRoboT/.config/nvim/'
alias tlab='cd ~/repos/Trading-Lab/'
alias .dots='cd ~/repos/DotRoboT/'
alias todos='v ~/repos/Code-Lab/todos.md'
# alias projects='cd ~/repos/Code-Lab/projects/'
alias pylab='cd ~/repos/Code-Lab/python-lab/'


# Edit config files
alias vzshrc='nvim ~/.zshrc'

# npm path
export PATH=$PATH:/home/ys/.npm-global/bin


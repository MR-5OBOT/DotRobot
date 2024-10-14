# Set ZINIT_HOME and initialize Zinit
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

# Add local bin to PATH
export PATH="$HOME/.local/bin:$PATH"

# Initialize Starship prompt
eval "$(starship init zsh)"

# Initialize Zoxide
eval "$(zoxide init zsh)"

# Add Zsh plugins (lazy loading)
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light aloxaf/fzf-tab

# Optimize completion
autoload -Uz compinit
compinit -C  # Use cache to speed up compinit
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
setopt AUTOCD              # Change directory just by typing its name
setopt PROMPT_SUBST        # Enable command substitution in prompt
setopt MENU_COMPLETE        # Automatically highlight first element of completion menu
setopt LIST_PACKED          # The completion menu takes less space
setopt AUTO_LIST           # Automatically list choices on ambiguous completion
setopt COMPLETE_IN_WORD    # Complete from both ends of a word

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
alias .dots='cd ~/repos/DotRobot/'
alias todos='v ~/repos/Code-Lab/todos.md'
alias pylab='cd ~/repos/Code-Lab/python-lab/'

# Edit config files
alias vzshrc='nvim ~/.zshrc'

# npm path
export PATH=$PATH:/home/ys/.npm-global/bin

# Regenerate the completion dump file for improved performance
# rm -f ~/.zcompdump
compinit -C

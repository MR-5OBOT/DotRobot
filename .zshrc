# Set ZINIT_HOME and initialize Zinit
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

# Initialize Starship prompt
eval "$(starship init zsh)"

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
HISTSIZE=1000
SAVEHIST=1000

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
alias makeenv='python3 -m venv venv && source venv/bin/activate'
alias .dots='cd ~/repos/DotRobot/'
alias vzshrc='nvim ~/.zshrc'
alias docker-repos='docker run -it -v /home/mr5obot/repos:/root/repos archlinux'

f() {
  local dir 
  dir=$(find "$HOME" -type d \
    -not -path '*/node_modules*' \
    -not -path '*/.cache*' \
    -not -path '*/__pycache__' \
    2> /dev/null | fzf \
      --height=20% \
      --layout=reverse \
      --info=hidden \
      --border \
      --margin=0%,49%,0%,0% )
  [ -n "$dir" ] && cd "$dir"
}

# Add local bin to PATH
export PATH="$HOME/.local/bin:$PATH"

# npm globals
export PATH="$HOME/.npm-global/bin:$PATH"
export http_proxy="http://192.168.135.2:8080"
export https_proxy="http://192.168.135.2:8080"
export HTTP_PROXY="http://192.168.135.2:8080"
export HTTPS_PROXY="http://192.168.135.2:8080"

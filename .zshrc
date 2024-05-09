# Set up the PATH
export PATH="$HOME/.local/bin:$PATH"

# Basic auto/tab complete:
autoload -U compinit
zmodload zsh/complist
compinit
_comp_options+=(globdots) # Include hidden files.

# EDITOR
export VISUAL=nvim
export EDITOR="$VISUAL"

# Enable command history
HISTFILE=~/.zsh_history
HISTSIZE=1000
SAVEHIST=1000

### ---- Completion options and styling -----------------------------------
zstyle ':completion:*' menu select # selectable menu
zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]-_}={[:upper:][:lower:]_-}' 'r:|=*' 'l:|=* r:|=*'  # case insensitive completion
zstyle ':completion:*' special-dirs true # Complete . and .. special directories
zstyle ':completion:*' list-colors '' # colorize completion lists

# -----------------------------------------------------
# START STARSHIP
# -----------------------------------------------------
eval "$(starship init zsh)"

# -----------------------------------------------------
# ALIASES
# -----------------------------------------------------
alias ff='fd --type f --hidden --exclude .git | fzf-tmux --preview "bat {}" -p --reverse | xargs -o sh -c '\''[ -z "$1" ] || nvim "$1"'\'' sh' # fzf-files
alias flist='kitty list-fonts | fzf'
alias lg='lazygit'
alias v='nvim'
alias free='free -h'
alias c='clear'
alias mv='mv -i'
alias rm='trash -v'
alias mkdir='mkdir -p -v'
alias myhost='nmtui'
alias mx='chmod a+x'
alias ..="cd .."
alias ...="cd ../../"
alias ls='eza -a --icons'
alias l.='ls -d .* --color=auto'
alias la='ls -Alh' # show hidden files

# -----------------------------------------------------
# CD TO REPOS
# -----------------------------------------------------
alias dlab='cd ~/repos/Dev-Lab/'
alias vlab='v ~/repos/MR-NV/nvim/'
alias tj='cd ~/repos/Dev-Lab/latex-projects/trading-journal/'
alias .dots='cd ~/repos/DotRoboT/'

# -----------------------------------------------------
# EDIT CONFIG FILES
# -----------------------------------------------------
alias vhypr='$EDITOR $HOME/.config/hypr/'
alias vbashrc='$EDITOR ~/.bashrc'
alias vzshrc='$EDITOR ~/.zshrc'


# Extracts any archive(s) (if unp isn't installed)
extract () {
	for archive in "$@"; do
		if [ -f "$archive" ] ; then
			case $archive in
				*.tar.bz2)   tar xvjf $archive    ;;
				*.tar.gz)    tar xvzf $archive    ;;
				*.bz2)       bunzip2 $archive     ;;
				*.rar)       rar x $archive       ;;
				*.gz)        gunzip $archive      ;;
				*.tar)       tar xvf $archive     ;;
				*.tbz2)      tar xvjf $archive    ;;
				*.tgz)       tar xvzf $archive    ;;
				*.zip)       unzip $archive       ;;
				*.Z)         uncompress $archive  ;;
				*.7z)        7z x $archive        ;;
				*)           echo "don't know how to extract '$archive'..." ;;
			esac
		else
			echo "'$archive' is not a valid file!"
		fi
	done
}

# ----------------------------------------------------
# IP address lookup
# ----------------------------------------------------
myip ()
     {
ip addr show | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*'
}

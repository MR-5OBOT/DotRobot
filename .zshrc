


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
alias grep='grep --color=auto'
alias lg='lazygit'
alias st='git status'
alias v='nvim'
alias free='free -h'
alias c='clear'
alias mv='mv -i'
alias rm='trash -v'
alias mkdir='mkdir -p -v'
alias hostmane='nmtui'
alias off='systemctl poweroff'
alias pid='pgrep -f'
alias targz='tar -czf' # file-name + files want to archive
alias ..="cd .."
alias ...="cd ../../"
alias ls='eza -a --icons'
alias l.='ls -d .* --color=auto'
alias la='ls -Alh' # show hidden files

alias hi="notify-send 'Hi there!' 'Welcome to MR5OBOT LAB! ' -i ''"

# -----------------------------------------------------
# CD TO REPOS
# -----------------------------------------------------
alias .dev='cd ~/repos/Dev-Lab/'
alias .dots='cd ~/repos/DotRoboT/'
alias .trading='cd ~/repos/trading-journal/'

# -----------------------------------------------------
# EDIT CONFIG FILES
# -----------------------------------------------------
alias .v='$EDITOR ~/.config/nvim/'
alias vhypr='$EDITOR $HOME/.config/hypr/'
alias vbashrc='$EDITOR ~/.bashrc'
alias vzshrc='$EDITOR ~/.zshrc'
alias vrofi='$EDITOR ~/.config/rofi/'
alias vwaybar='$EDITOR ~/.config/waybar/'
alias vkitty='$EDITOR ~/.config/kitty/'
alias vtjournal='$EDITOR ~/repos/Dev-Lab/latex-projects/trading-jounral/'

# -----------------------------------------------------
# chmod aliases
# -----------------------------------------------------
alias mx='chmod a+x'
alias 000='chmod -R 000'
alias 644='chmod -R 644'
alias 666='chmod -R 666'
alias 755='chmod -R 755'
alias 777='chmod -R 777'

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

# -----------------------------------------------------
# SYSTEM
# -----------------------------------------------------

# alias update-grub='sudo grub-mkconfig -o /boot/grub/grub.cfg'
# alias setkb='setxkbmap de;echo "Keyboard set back to de."'




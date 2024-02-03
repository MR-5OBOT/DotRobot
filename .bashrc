#!/bin/bash


# If not running interactively, don't do anything
[[ $- != *i* ]] && return
PS1='[\u@\h \W]\$ '


# starship cfg
eval "$(starship init bash)" 


export PATH="$HOME/.local/bin:$PATH"


# git function for eaasy push for each branch
lazyg() {
   git add .
   git commit -m "$1"
   git push origin $(git rev-parse --abbrev-ref HEAD):$2
}


# Alias's to modified commands
alias lg='lazygit'
alias st='git status'
alias .v='nvim ~/MR-5OBOT/MR-NV/'
alias .dots='cd ~/MR-5OBOT/DotRoboT/'
alias .home='cd ~/MR-5OBOT/'
alias v='nvim'
alias c='clear'
alias mv='mv -i'
alias rm='trash -v'
alias mkdir='mkdir -p -v'
alias wifi='nmtui'
alias off='systemctl poweroff'
alias winclass="xprop | grep 'CLASS'"
alias pid='pgrep -f'
alias targz='tar -czf' # file-name + files want to archive
# alias cp='cp -i'
alias ..="cd .."
alias cd..="cd .."
alias ...="cd ../../"
# Better copying
alias cpv='rsync -avh --info=progress2'
alias c='clear'
# cd into the old directory
alias bd='cd "$OLDPWD"'

# Alias's for multiple directory listing commands
alias ls='lsd -a --group-directories-first'
alias l.='ls -d .* --color=auto'
alias la='ls -Alh' # show hidden files

# alias chmod commands
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


# IP address lookup
myip ()
     {
ip addr show | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*'
}



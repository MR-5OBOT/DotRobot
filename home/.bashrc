#!/bin/bash


# If not running interactively, don't do anything
[[ $- != *i* ]] && return
PS1='[\u@\h \W]\$ '

# Define Editor
export EDITOR=nvim


alias st='git status'
# git function for eaasy push for each branch
lazygit() {
  git add .
  git commit -m "$1"
  git push origin $(git rev-parse --abbrev-ref HEAD):$2
}

eval "$(starship init bash)" # starship cfg

~/.config/scripts/kitty-gifs.sh # my gifs terminal logos


# Alias's to modified commands
alias .v='nvim ~/MR-5OBOT/DotRoboT/.config/nvim'
alias .dots='cd ~/MR-5OBOT/DotRoboT/'
alias .home='cd ~/MR-5OBOT/'
alias v='nvim'
# alias cp='cp -i'
alias mv='mv -i'
alias rm='trash -v'
alias mkdir='mkdir -p'
alias ping='ping -c 10'
alias cls='clear'
alias sv='sudo vi'

# Change dirs
alias ..="cd .."
alias cd..="cd .."
alias ...="cd ../../"
alias ....="cd ../../../"

# Better copying
alias cpv='rsync -avh --info=progress2'
alias c='clear'

# quick restart 
alias rmako=~/.config/scripts/mako-start.sh
alias rdunst=~/.config/scripts/dunst-start.sh
alias rwaybar=~/.config/scripts/togglebar.sh

# Change directory aliases
alias home='cd ~'

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

# Automatically install the needed support files for this .bashrc file
install_bashrc_support ()
{
	local dtype
	dtype=$(distribution)

	if [ $dtype == "redhat" ]; then
		sudo yum install multitail tree joe
	elif [ $dtype == "suse" ]; then
		sudo zypper install multitail
		sudo zypper install tree
		sudo zypper install joe
	elif [ $dtype == "debian" ]; then
		sudo apt-get install multitail tree joe
	elif [ $dtype == "gentoo" ]; then
		sudo emerge multitail
		sudo emerge tree
		sudo emerge joe
	elif [ $dtype == "mandriva" ]; then
		sudo urpmi multitail
		sudo urpmi tree
		sudo urpmi joe
	elif [ $dtype == "slackware" ]; then
		echo "No install support for Slackware"
	else
		echo "Unknown distribution"
	fi
}

# IP address lookup
myip ()
     {
ip addr show | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*'
}



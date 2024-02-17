#!/bin/bash

# If not running interactively, don't do anything
[[ $- != *i* ]] && return
PS1='[\u@\h \W]\$ '

export PATH="$HOME/.local/bin:$PATH"

# -----------------------------------------------------
# START STARSHIP
# -----------------------------------------------------
eval "$(starship init bash)"

# -----------------------------------------------------
# SOURCE CONFIGs
# -----------------------------------------------------
source ~/.config/zsh/aliases.zsh
source ~/.config/zsh/env.zsh

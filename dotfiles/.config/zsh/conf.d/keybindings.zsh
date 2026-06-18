# Keybindings (vi mode).

bindkey -v
export KEYTIMEOUT=5

bindkey -M viins '^?' backward-delete-char   # Backspace past insert point
bindkey -M viins '^H' backward-delete-char   # Ctrl-H same
bindkey '^ ' autosuggest-accept              # Ctrl-Space accepts suggestion
bindkey '\ef' forward-word                   # Alt-f jumps a word forward

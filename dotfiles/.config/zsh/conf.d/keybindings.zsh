# Keybindings (vi mode).

bindkey -v
export KEYTIMEOUT=5

bindkey -M viins '^?' backward-delete-char   # Backspace past insert point
bindkey -M viins '^H' backward-delete-char   # Ctrl-H same
bindkey '^ ' autosuggest-accept              # Ctrl-Space accepts suggestion
bindkey '\ef' forward-word                   # Alt-f jumps a word forward

# Caps+W/B (keyd sends Ctrl+Right/Left) jump words, Caps+0/4 (Home/End) jump to line
# start/end. Home/End arrive as ^[[H/^[[F in bare kitty but ^[[1~/^[[4~ inside tmux.
bindkey -M viins '^[[1;5C' forward-word
bindkey -M viins '^[[1;5D' backward-word
for k in '^[[H' '^[[1~'; do bindkey -M viins $k beginning-of-line; done
for k in '^[[F' '^[[4~'; do bindkey -M viins $k end-of-line; done

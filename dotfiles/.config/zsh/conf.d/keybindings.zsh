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

# Ctrl+R: fuzzy search old commands (vi mode had reset it to "redisplay"). Only fzf's
# key bindings, not its completion.zsh (would fight fzf-tab over Tab). Empty vars turn
# off its Ctrl+T (pick a file) and Alt+C (cd into a folder); delete them to enable.
FZF_CTRL_T_COMMAND= FZF_ALT_C_COMMAND=
[[ -r /usr/share/fzf/key-bindings.zsh ]] && source /usr/share/fzf/key-bindings.zsh

# Cursor shows the vi mode, like nvim: bar while typing, block in normal mode (Esc).
# Hook widgets, so starship's own keymap-select (prompt redraw) still runs.
autoload -Uz add-zle-hook-widget
_vi_cursor() { [[ $KEYMAP == vicmd ]] && printf '\e[2 q' || printf '\e[6 q'; }
zle -N _vi_cursor
add-zle-hook-widget keymap-select _vi_cursor
add-zle-hook-widget line-init _vi_cursor

# Esc then v: edit the command line in $EDITOR (nvim); :wq puts it back, Enter runs it.
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd v edit-command-line

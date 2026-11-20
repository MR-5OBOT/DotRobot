# Keybindings (vi mode).

bindkey -v
export KEYTIMEOUT=1 # 10 ms: Alt+key still reads as one key, but a fast Esc then key doesn't

bindkey -M viins '^?' backward-delete-char   # Backspace past insert point
bindkey -M viins '^H' backward-delete-char   # Ctrl-H same
bindkey '^ ' autosuggest-accept              # Ctrl-Space accepts suggestion
bindkey '\ef' forward-word                   # Alt-f jumps a word forward

# zinit binds Alt+Shift+Q to its symbol browser when it loads; an empty key
# turns that off (keybindings.zsh runs before plugins.zsh).
zstyle ':zinit:browse-symbol' key ''

# Alt+H/J/K/L/X/Space belong to kitty (workflow.conf), tmux or nvim. Any that reach
# zsh would arrive as Esc+key and silently drop you into normal mode running that key, so
# here they do nothing. A real no-op widget: binding an Esc sequence to undefined-key
# stores nothing and leaves it unbound.
_ignore_key() { :; }
zle -N _ignore_key
for m in viins vicmd; do for k in h j k l x ' '; do bindkey -M $m "\e$k" _ignore_key; done; done

# Ctrl+D clears the whole line and never exits the shell (on an empty line it used to,
# closing the pane unasked): type exit instead. Ctrl+U no longer clears; Ctrl+W
# still deletes a word back. Ctrl+G's completion listing and Ctrl+K's literal ^K are off.
setopt IGNORE_EOF
_clear_line() { zle kill-whole-line; } # function widget: IGNORE_EOF stays silent on an empty line
zle -N _clear_line
for m in viins vicmd; do bindkey -M $m '^D' _clear_line; bindkey -M $m '^G' undefined-key; done
bindkey -M viins '^U' undefined-key
bindkey -M viins '^W' vi-backward-kill-word
bindkey -M viins '^K' undefined-key

# Ctrl+V pastes the Wayland clipboard (Ctrl+Shift+V is kitty's own paste, it never
# reaches zsh). Ctrl+Q's literal-next is off.
_paste_clipboard() {
  local text
  text=$(wl-paste --no-newline 2>/dev/null) || return
  LBUFFER+=$text
}
zle -N _paste_clipboard
bindkey -M viins '^V' _paste_clipboard
bindkey -M viins '^Q' undefined-key

# Caps+W/B (keyd sends Ctrl+Right/Left) jump words, Caps+0/4 (Home/End) jump to line
# start/end. Keeping the Ctrl+arrow bindings also keeps physical Ctrl+arrows working;
# zsh cannot tell the two apart. Home/End arrive as ^[[H/^[[F in bare kitty but
# ^[[1~/^[[4~ inside tmux. Normal mode too: unbound there, the Esc ran the rest as vi
# commands (Ctrl+Right's "5C" wiped the line).
for m in viins vicmd; do
  bindkey -M $m '^[[1;5C' forward-word
  bindkey -M $m '^[[1;5D' backward-word
  for k in '^[[H' '^[[1~'; do bindkey -M $m $k beginning-of-line; done
  for k in '^[[F' '^[[4~'; do bindkey -M $m $k end-of-line; done
done
# Caps+U/D/G/Shift+G (PageUp/PageDown/Ctrl+Home/Ctrl+End) scroll in tmux or kitty, not here.
# Unbound, their Esc dropped zsh into normal mode and ran the rest as vi commands.
for m in viins vicmd; do for k in '^[[5~' '^[[6~' '^[[1;5H' '^[[1;5F'; do bindkey -M $m $k _ignore_key; done; done

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

# Normal mode y / d (and Y / D) also copy to the clipboard: cut or copy part of the command
# you're typing (tmux copy mode's x did this before kitty). x and c stay zsh-only, so a
# one-character fix doesn't overwrite the clipboard.
_clip_cut() { zle .$WIDGET && print -rn -- "$CUTBUFFER" | wl-copy 2>/dev/null; }
for w in vi-yank vi-yank-whole-line vi-delete vi-kill-eol; do zle -N $w _clip_cut; done
unset w

# Normal mode: no vi history search on / or ?; Ctrl+R in typing mode does that.
bindkey -M vicmd '/' undefined-key
bindkey -M vicmd '?' undefined-key

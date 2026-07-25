# ~/.config/zsh/.zshrc
# Interactive shell config. Environment lives in .zshenv; each section below
# is a file in conf.d/ and is sourced in the order listed.

ZDOTDIR="${ZDOTDIR:-$HOME/.config/zsh}"
export ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"

# Load sections in order: options -> completion styles -> the rest, with
# plugins last (zinit runs compinit, so completion styles must precede it).
for _frag in options completion aliases functions keybindings plugins; do
  [[ -r "$ZDOTDIR/conf.d/$_frag.zsh" ]] && source "$ZDOTDIR/conf.d/$_frag.zsh"
done
unset _frag

# Greeting
# kitty-direct images stick over tmux panes; use text logo inside tmux
if command -v fastfetch >/dev/null 2>&1; then
  [[ -n $TMUX ]] && fastfetch --logo none || fastfetch
fi

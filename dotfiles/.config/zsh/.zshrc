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
# Image logos need a graphics protocol the terminal receives directly; tmux
# forwards none of them, so keep the text logo whenever it is in the way.
if command -v fastfetch >/dev/null 2>&1; then
  [[ -n $TMUX ]] && fastfetch --logo none || fastfetch
fi

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
# tmux forwards no graphics protocol, so kitty-direct images stick over panes:
# text logo inside tmux, image outside. config.jsonc keeps logo type "none",
# which is why the image has to be passed on the command line.
if command -v fastfetch >/dev/null 2>&1; then
  if [[ -n $TMUX ]]; then
    fastfetch --logo none
  else
    fastfetch --logo-type kitty-direct --logo "$HOME/.config/fastfetch/gifs/pochita.gif"
  fi
fi

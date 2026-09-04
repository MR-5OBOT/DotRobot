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
# config.jsonc sets the logo type/size; the source is randomised here because
# fastfetch won't take a directory. kitty-icat renders the same in and out of tmux.
if command -v fastfetch >/dev/null 2>&1; then
  _logos=(${XDG_CONFIG_HOME:-$HOME/.config}/fastfetch/{gifs,pngs}/*(N.))
  # two expansions, not one: ${x:+a b} stays a single word in zsh
  fastfetch ${_logos:+--logo} ${_logos:+$_logos[RANDOM%$#_logos+1]}
  unset _logos
fi

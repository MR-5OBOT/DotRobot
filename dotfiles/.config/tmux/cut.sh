#!/bin/bash
# Copy-mode "cut": always copy the selection; if it sits on the row the app's
# cursor is on (the prompt being typed), also delete it there via arrows + Backspace.
# ponytail: works in cells, so wide glyphs (emoji/CJK) earlier on the row skew it,
# and selecting into zsh-autosuggest/RPROMPT text over-moves. Single-row only.
p=$1 on=$2 sx=$3 sy=$4 ex=$5 ey=$6 cx=$7 cy=$8 hs=$9
tmux send -t "$p" -X copy-pipe-and-cancel wl-copy
[ "$on" = 1 ] && [ "$sy" = $((hs + cy)) ] && [ "$ey" = "$sy" ] || exit 0
lo=$((sx < ex ? sx : ex)) hi=$((sx > ex ? sx : ex))
line=$(tmux capture-pane -p -t "$p" -S "$cy" -E "$cy")
sel=${line:lo:hi-lo+1}
sel=${sel%"${sel##*[![:space:]]}"} # empty cells past the text aren't deletable
[ -n "$sel" ] || exit 0
hi=$((lo + ${#sel} - 1))
d=$((hi + 1 - cx))
if [ $d -gt 0 ]; then tmux send -t "$p" -N $d Right
elif [ $d -lt 0 ]; then tmux send -t "$p" -N $((-d)) Left; fi
tmux send -t "$p" -N ${#sel} BSpace

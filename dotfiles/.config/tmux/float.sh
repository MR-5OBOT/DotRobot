#!/bin/sh
set -eu

if [ "$1" = attach ]; then
  session=$2
  parent=$3
  socket=${TMUX%,*,*}
  created=false
  if ! tmux has-session -t "=$session" 2>/dev/null; then
    size=$(stty size)
    tmux new-session -d -s "$session" -c "$PWD" \
      -x "${size#* }" -y "${size% *}" 'sleep infinity' \; \
      set-option -t "=$session:" status off \; \
      set-option -t "=$session:" detach-on-destroy on \; \
      set-option -w -t "=$session:" window-status-format '' \; \
      set-option -w -t "=$session:" window-status-separator '' \; \
      set-option -p -t "=$session:" allow-passthrough all
    created=true
  fi
  # Share image uploads with the outer client; only placeholder cells are nested.
  # The backing window is unlinked when hidden and is never selected here.
  window=$(tmux display-message -p -t "=$session:" '#{window_id}')
  tmux link-window -d -s "$window" -t "$parent:"
  link="$parent:$window"
  trap 'tmux unlink-window -k -t "$link" 2>/dev/null || :' EXIT
  trap 'exit' HUP INT TERM
  if "$created"; then
    # Start the normal shell only once its client and image route are ready.
    shell=$(tmux show-option -gv default-shell)
    env -u TMUX tmux -S "$socket" attach-session -t "=$session" \; \
      respawn-pane -k -t "=$session:" "$shell" -l
  else
    env -u TMUX tmux -S "$socket" attach-session -t "=$session"
  fi
  exit
fi

pane=$2
session=$(tmux show-option -pqv -t "$pane" @float-session)
if [ "$1" = close ]; then
  tmux kill-window -t "=$session:"
  exit
fi
view=$(tmux list-panes -t "$pane" -f '#{@float-session}' -F '#{pane_id}')
if [ -n "$view" ]; then
  tmux kill-pane -t "$view"
else
  parent=$(tmux display-message -p -t "$pane" '#{session_id}')
  window=$(tmux display-message -p -t "$pane" '#{window_id}')
  session="floating-${window#@}"
  cwd=$(tmux display-message -p -t "$pane" '#{pane_current_path}')
  view=$(tmux new-pane -P -F '#{pane_id}' -t "$pane" -c "$cwd" \
    -x 85% -y 80% -X 7% -Y 10% \
    sh "$0" attach "$session" "$parent")
  tmux set-option -p -t "$view" @float-session "$session"
fi

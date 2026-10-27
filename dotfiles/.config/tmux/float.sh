#!/bin/sh
set -eu

# Clean up any legacy per-window floating sessions
prune_legacy_sessions() {
  sessions=$(tmux list-sessions -F '#{session_name}' 2>/dev/null | grep '^floating-' || true)
  [ -z "$sessions" ] && return 0
  for s in $sessions; do
    tmux kill-session -t "=$s" 2>/dev/null || :
  done
}

action="${1:-toggle}"

if [ "$action" = attach ]; then
  session="${2:?missing session name}"
  parent="${3:?missing parent session id}"
  socket="${TMUX%,*,*}"
  created=false

  if ! tmux has-session -t "=$session" 2>/dev/null; then
    size=$(stty size 2>/dev/null || echo "24 80")
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
    shell=$(tmux show-option -gv default-shell 2>/dev/null || true)
    shell="${shell:-${SHELL:-/bin/sh}}"
    env -u TMUX tmux -S "$socket" attach-session -t "=$session" \; \
      respawn-pane -k -t "=$session:" "$shell" -l
  else
    env -u TMUX tmux -S "$socket" attach-session -t "=$session"
  fi
  exit 0
fi

pane="${2:-$(tmux display-message -p '#{pane_id}')}"
session=$(tmux show-option -pqv -t "$pane" @float-session || true)

if [ "$action" = close ]; then
  session="${session:-floating}"
  tmux kill-session -t "=$session" 2>/dev/null || :
  view=$(tmux list-panes -a -f '#{@float-session}' -F '#{pane_id}' 2>/dev/null || true)
  for v in $view; do
    tmux kill-pane -t "$v" 2>/dev/null || :
  done
  exit 0
fi

# Toggling float window (Single Shared Scratchpad):
prune_legacy_sessions

# Check if float is currently visible in this window
current_view=$(tmux list-panes -t "$pane" -f '#{@float-session}' -F '#{pane_id}' 2>/dev/null || true)

if [ -n "$current_view" ]; then
  # Already visible in this window -> hide it
  for v in $current_view; do
    tmux kill-pane -t "$v" 2>/dev/null || :
  done
else
  # Not visible in this window:
  # First, close any floating view left open in other windows so scratchpad moves here
  other_views=$(tmux list-panes -a -f '#{@float-session}' -F '#{pane_id}' 2>/dev/null || true)
  for v in $other_views; do
    tmux kill-pane -t "$v" 2>/dev/null || :
  done

  # Single shared scratchpad session across all windows
  session="floating"
  parent=$(tmux display-message -p -t "$pane" '#{session_id}')
  cwd=$(tmux display-message -p -t "$pane" '#{pane_current_path}')
  view=$(tmux new-pane -A -P -F '#{pane_id}' -t "$pane" -c "$cwd" \
    -x 68% -y 80% -X 16% -Y 10% \
    -B single -T ' float ' \
    -S 'fg=#BE4277' \
    sh "$0" attach "$session" "$parent")
  tmux set-option -p -t "$view" @float-session "$session"
fi

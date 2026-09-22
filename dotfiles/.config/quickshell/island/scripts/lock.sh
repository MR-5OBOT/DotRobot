#!/bin/sh
# The one way into the lock screen: hypridle's lock_cmd, the ALT+L bind and the
# island's Power surface all come through here.
#
# Anything playing is paused first — a browser tab, a music player, a video —
# so the room goes quiet when the screen does. Players are asked over MPRIS with
# busctl (systemd ships it; no playerctl dependency). A player that cannot pause
# just refuses, and the error is dropped.
# No `set -e` anywhere near this: with nothing playing the grep below exits 1,
# and the screen would then never lock. Pausing is best-effort, locking is not.

# Already locked: never stack a second hyprlock on top of the running one.
pidof hyprlock >/dev/null 2>&1 && exit 0

pause_all() {
    busctl --user list --no-legend 2>/dev/null \
        | awk '{ print $1 }' \
        | grep '^org\.mpris\.MediaPlayer2\.' \
        | while IFS= read -r player; do
            busctl --user call "$player" /org/mpris/MediaPlayer2 \
                org.mpris.MediaPlayer2.Player Pause >/dev/null 2>&1
        done
}

# Pausing once is not enough: a tab can start again while the screen is locked
# (after waking from suspend, say). So for as long as hyprlock runs, any player
# that reports "Playing" is paused again. When hyprlock exits the monitor is
# killed, the pipe closes and the loop ends with it.
# hyprlock's own log goes to stderr so the loop never reads it.
{
    dbus-monitor --session "type='signal',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged',path='/org/mpris/MediaPlayer2',arg0='org.mpris.MediaPlayer2.Player'" 2>/dev/null &
    pause_all
    hyprlock >&2
    kill $! 2>/dev/null
} | while IFS= read -r line; do
    case $line in *'"Playing"'*) pause_all ;; esac
done

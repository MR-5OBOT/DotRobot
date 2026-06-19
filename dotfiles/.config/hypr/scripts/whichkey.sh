#!/usr/bin/env bash
# Hyprland keybind cheatsheet — themed rofi popup, two columns. Esc / click to close.
THEME="$HOME/.config/rofi/cheatsheet.rasi"
KEY="#862F55"
ACC="#742849"
KEYW=14   # key sub-column width
CELLW=40  # left-column width before the right column starts

# Each entry: "type|keys|desc"   type: h=header, k=bind
LEFT=(
	"h|Apps|"
	"k|Super Enter|terminal"
	"k|Super Space|app launcher"
	"k|Super V|clipboard history"
	"k|Super N|notifications"
	"k|Super X|power menu"
	"k|Super W|wallpaper picker"
	"k|Super B|toggle waybar"
	"k|Super ⇧ C|pick color → hex"
	"k|Super ⇧ I|speedtest"
	"k|Alt L|lock screen"
	"h|Window|"
	"k|Super Q|close window"
	"k|Super C|center window"
	"k|Alt Space|toggle floating"
	"k|Super ⇧ F|fullscreen"
	"k|Super G|toggle group"
)
RIGHT=(
	"h|Focus / Move / Resize|"
	"k|Super h j k l|focus ← ↓ ↑ →"
	"k|Super Alt …|move window"
	"k|Super Ctrl …|resize window"
	"h|Workspaces|"
	"k|Super 1-9|switch workspace"
	"k|Super ⇧ 1-9|send window → ws"
	"h|Screenshot / Record|"
	"k|Print|screenshot region"
	"k|Super R|start recording"
	"k|Super ⇧ R|stop recording"
	"h|Mouse|"
	"k|Super + LMB|move window"
	"k|Super + RMB|resize window"
	"k|Side back|mic mute"
	"k|Side forward|screenshot"
)

# cell <entry> -> sets MK (pango markup) and VIS (visible char length)
cell() {
	local t="${1%%|*}" rest="${1#*|}" a b sp kp
	a="${rest%%|*}"
	b="${rest#*|}"
	if [ "$t" = h ]; then
		MK="<span foreground=\"$ACC\"><b>▌ $a</b></span>"
		VIS=$((2 + ${#a}))
	else
		kp=$((KEYW - ${#a}))
		((kp < 1)) && kp=1
		printf -v sp '%*s' "$kp" ''
		MK="<b><span foreground=\"$KEY\">$a</span></b>$sp$b"
		VIS=$((${#a} + kp + ${#b}))
	fi
}

list() {
	local n=${#LEFT[@]} i lmk lvis rmk gap g
	((${#RIGHT[@]} > n)) && n=${#RIGHT[@]}
	for ((i = 0; i < n; i++)); do
		if [ -n "${LEFT[$i]+x}" ]; then
			cell "${LEFT[$i]}"
			lmk="$MK"
			lvis="$VIS"
		else
			lmk=""
			lvis=0
		fi
		if [ -n "${RIGHT[$i]+x}" ]; then
			cell "${RIGHT[$i]}"
			rmk="$MK"
		else
			rmk=""
		fi
		gap=$((CELLW - lvis))
		((gap < 1)) && gap=1
		printf -v g '%*s' "$gap" ''
		printf '%s%s%s\n' "$lmk" "$g" "$rmk"
	done
}

list | rofi -dmenu -markup-rows -theme "$THEME" \
	-mesg "<b><span foreground=\"$ACC\">Hyprland — which-key</span></b>" >/dev/null

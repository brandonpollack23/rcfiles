#!/bin/sh
# Show the current level in SwayOSD after a media key has changed it.
# Usage: osd.sh sink|source|brightness
#
# SwayOSD 0.3.2 only reacts to Caps/Num/Scroll Lock from its libinput backend,
# and `swayosd-client --output-volume` would change the volume itself, so the
# binds in conf/keymaps.lua keep using wpctl and brightnessctl and this only
# displays the result. Icon names are the ones bundled in swayosd-server.

# "Volume: 0.45 [MUTED]" -> "45 [MUTED]"
volume() {
	wpctl get-volume "$1" | awk '{ printf "%d %s\n", $2 * 100 + 0.5, $3 }'
}

# 45 -> 0.45, capped at 1
fraction() {
	awk "BEGIN { f = $1 / 100; print (f > 1 ? 1 : f) }"
}

show() {
	swayosd-client --custom-icon "$1" --custom-progress "$2"
}

show_volume() {
	set -- "$1" $(volume "$2")
	if test -n "$3" || test "$2" -eq 0; then
		show "$1-volume-muted-symbolic" 0
		return
	fi
	if test "$2" -le 33; then
		level=low
	elif test "$2" -le 66; then
		level=medium
	else
		level=high
	fi
	show "$1-volume-$level-symbolic" "$(fraction "$2")"
}

case "$1" in
sink) show_volume sink @DEFAULT_AUDIO_SINK@ ;;
source) show_volume source @DEFAULT_AUDIO_SOURCE@ ;;
brightness)
	# Same -e4 curve as the binds, so the bar moves in even steps.
	pct=$(brightnessctl -e4 -m info 2>/dev/null | cut -d, -f4 | tr -d %)
	test -n "$pct" || exit 0
	show display-brightness-symbolic "$(fraction "$pct")"
	;;
*)
	echo "usage: $0 sink|source|brightness" >&2
	exit 2
	;;
esac

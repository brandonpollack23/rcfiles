#!/bin/sh
# Text for the dynamic labels in hyprlock.conf. Each prints one line, or nothing
# to hide its label. hyprlock runs these from its resource thread, so none may
# block for long: network calls are cached and time-limited.
#   lock-info.sh weather    current conditions from wttr.in (IP location, °C)
#   lock-info.sh greeting   "Good evening, <first name>"
#   lock-info.sh reboot     restart hint after a kernel or NVIDIA driver update
#   lock-info.sh capslock   warning while Caps Lock is on
#   lock-info.sh footer     host and uptime

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/hyprlock"
WEATHER_TTL=900 # seconds

weather() {
	cache="$CACHE_DIR/weather"
	mkdir -p "$CACHE_DIR"
	age=$(($(date +%s) - $(stat -c %Y "$cache" 2>/dev/null || echo 0)))
	if test "$age" -ge "$WEATHER_TTL"; then
		# %c condition emoji, %t temperature, %C condition name; m = metric.
		new=$(curl -fsS -m 3 'https://wttr.in/?m&format=%c+%t+%C' 2>/dev/null)
		# wttr.in answers errors with prose; keep only short, sane replies.
		case "$new" in
		*°*) test "${#new}" -lt 60 && printf '%s\n' "$new" >"$cache" ;;
		esac
	fi
	cat "$cache" 2>/dev/null
}

greeting() {
	hour=$(date +%-H)
	if test "$hour" -lt 5; then
		part="night"
	elif test "$hour" -lt 12; then
		part="morning"
	elif test "$hour" -lt 18; then
		part="afternoon"
	else
		part="evening"
	fi
	# First name from the account's full name, else from git (.gitconfig), else the login.
	name=$(getent passwd "$USER" | cut -d: -f5 | cut -d, -f1)
	test -n "$name" || name=$(git config --global user.name 2>/dev/null)
	name=${name%% *}
	echo "Good $part, ${name:-$USER}"
}

reboot() {
	reasons=""
	# Arch removes the running kernel's modules when a new kernel is installed.
	if ! test -d "/usr/lib/modules/$(uname -r)"; then
		reasons="kernel"
	elif test -r /sys/module/nvidia/version; then
		loaded=$(cat /sys/module/nvidia/version)
		installed=$(modinfo -F version nvidia 2>/dev/null)
		if test -n "$installed" && test "$loaded" != "$installed"; then
			reasons="NVIDIA driver $loaded → $installed"
		fi
	fi
	test -n "$reasons" && echo "󰜉  Restart to finish updating: $reasons"
}

capslock() {
	for led in /sys/class/leds/*::capslock/brightness; do
		if test "$(cat "$led" 2>/dev/null)" = 1; then
			echo "󰪛  Caps Lock is on"
			return
		fi
	done
}

footer() {
	echo "󰒋  $(cat /proc/sys/kernel/hostname)   ·   󰔛  $(uptime -p | sed 's/^up //')"
}

case "$1" in
weather | greeting | reboot | capslock | footer) "$1" ;;
*)
	echo "usage: $0 weather|greeting|reboot|capslock|footer" >&2
	exit 1
	;;
esac

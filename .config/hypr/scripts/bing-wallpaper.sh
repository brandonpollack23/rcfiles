#!/bin/sh
# Bing image of the day as the wallpaper, set with awww.
#   bing-wallpaper.sh start     start the timer and fetch now (Hyprland startup)
#   bing-wallpaper.sh refresh   fetch now through the service (system menu)
#   bing-wallpaper.sh update    fetch today's image if it is new and show it
#                               (what bing-wallpaper.service runs)
#   bing-wallpaper.sh title     print the current image's title
#   bing-wallpaper.sh open      open the Bing page about the current image
#   bing-wallpaper.sh frequency [hourly | daily | <OnCalendar spec>]
#                               print or set how often the timer checks for a
#                               new image; kept in $XDG_STATE_HOME/hypr
# Images and their metadata are kept in $XDG_CACHE_HOME/bing-wallpaper for
# KEEP_DAYS days; current.jpg and current.json point at the one on screen.
# The units are in ~/.config/systemd/user/bing-wallpaper.{service,timer}; the
# timer is not enabled, only started from Hyprland, and the service skips its
# run once that Hyprland instance is gone.

API='https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=en-US'
KEEP_DAYS=30
DEFAULT_FREQUENCY=daily
dir="${XDG_CACHE_HOME:-$HOME/.cache}/bing-wallpaper"
state_file="${XDG_STATE_HOME:-$HOME/.local/state}/hypr/bing-wallpaper-frequency"

frequency() {
	cat "$state_file" 2>/dev/null || echo "$DEFAULT_FREQUENCY"
}

# Overrides the timer's OnCalendar with a runtime drop-in (gone at reboot,
# rewritten at every start), so the unit file in rcfiles stays untouched.
apply_frequency() {
	dropin="$XDG_RUNTIME_DIR/systemd/user/bing-wallpaper.timer.d"
	mkdir -p "$dropin"
	printf '[Timer]\nOnCalendar=\nOnCalendar=%s\n' "$(frequency)" >"$dropin/frequency.conf"
	systemctl --user daemon-reload
}

# At login the daemon may still be starting; give it a few seconds.
wait_for_daemon() {
	tries=50
	until awww query >/dev/null 2>&1; do
		tries=$((tries - 1))
		test "$tries" -gt 0 || return 1
		sleep 0.1
	done
}

show() {
	wait_for_daemon && awww img "$1" --transition-type fade
}

# Downloads today's image and metadata unless they are already here, and
# prints the image's path.
fetch() {
	mkdir -p "$dir"
	meta=$(curl -fsS --max-time 20 "$API" | jq -e '.images[0]') || return 1
	name=$(printf '%s' "$meta" | jq -r '.startdate')
	image="$dir/$name.jpg"
	if ! test -s "$image"; then
		base=$(printf '%s' "$meta" | jq -r '.urlbase')
		curl -fsSL --max-time 120 "https://www.bing.com${base}_UHD.jpg" -o "$image.tmp" &&
			mv "$image.tmp" "$image" || {
			rm -f "$image.tmp"
			return 1
		}
	fi
	printf '%s' "$meta" >"$dir/$name.json"
	printf '%s\n' "$image"
}

cleanup() {
	find "$dir" -maxdepth 1 -type f \( -name '*.jpg' -o -name '*.json' \) \
		-mtime +"$KEEP_DAYS" -delete
}

update() {
	image=$(fetch) || exit 1
	name=$(basename "$image" .jpg)
	# Don't replay the fade every hour when the image is already on screen.
	# A fresh daemon (new login, restart) shows nothing or its cached image,
	# so check what it displays too.
	if test "$(readlink "$dir/current.jpg")" != "$name.jpg" ||
		! awww query 2>/dev/null | grep -qF "$image"; then
		show "$image" || exit 1
		ln -sfn "$name.jpg" "$dir/current.jpg"
		ln -sfn "$name.json" "$dir/current.json"
	fi
	cleanup
}

case "$1" in
start)
	systemctl --user import-environment WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE &&
		apply_frequency &&
		systemctl --user start --no-block bing-wallpaper.timer bing-wallpaper.service
	;;
frequency)
	if test -z "$2"; then
		frequency
		exit
	fi
	systemd-analyze calendar "$2" >/dev/null || exit 1
	mkdir -p "${state_file%/*}"
	echo "$2" >"$state_file"
	apply_frequency && systemctl --user restart bing-wallpaper.timer
	;;
refresh) systemctl --user start --no-block bing-wallpaper.service ;;
update) update ;;
title) jq -r '.title' "$dir/current.json" 2>/dev/null ;;
open)
	link=$(jq -r '.copyrightlink // empty' "$dir/current.json" 2>/dev/null)
	test -n "$link" && xdg-open "$link"
	;;
*)
	echo "usage: $0 start | refresh | update | title | open | frequency [spec]" >&2
	exit 1
	;;
esac

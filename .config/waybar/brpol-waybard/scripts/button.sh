#!/bin/sh
# Feeds one waybar button from the daemon's FIFO for it:
#
#   button.sh win3
#
# This is every scripted module's `exec`. It replaces a Python interpreter per
# button with a `cat`: the daemon computes all 39 buttons from one snapshot and
# writes each one's JSON line to its own pipe.
FIFO="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/waybar/$1"

# At login waybar and the daemon come up together, so the pipe may not exist
# for a moment. Waybar's restart-interval would retry, but waiting here keeps
# it from respawning us once a second while the daemon starts.
tries=100
until test -p "$FIFO"; do
	tries=$((tries - 1))
	test "$tries" -gt 0 || exit 1
	sleep 0.1
done

# A pipe is not a file: the line already in it belongs to whoever reads first,
# and a button waybar just restarted has none. Ask for one before reading.
"$(dirname "$(readlink -f "$0")")/ctl.sh" prime "$1"

exec cat "$FIFO"

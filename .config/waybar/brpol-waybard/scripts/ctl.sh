#!/bin/sh
# Sends one command to the waybar taskbar daemon:
#
#   ctl.sh refresh      recompute, for the group changes Hyprland has no event for
#   ctl.sh prime <name> re-send what button <name> shows, for a reader that has
#                       only just attached; waybar runs this as a button comes up
#   ctl.sh focus <n>    focus the window in taskbar slot n
#   ctl.sh toggle <n>   show or hide hidden-workspace slot n
#   ctl.sh nightlight   night light on or off
#
# Silently does nothing when the daemon is not running: the bar is not worth
# blocking a click or the compositor over.
CTL="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/waybar/control"

# `test`, not `[`: Hyprland reads a command starting with `[` as inline window
# rules. Also guards against the redirect below creating a regular file where
# the FIFO should be.
test -p "$CTL" || exit 0

# The daemon holds the read end open, so this never blocks while it is alive.
# The timeout is for the case where it died with the FIFO still in place.
timeout 1 sh -c 'printf "%s\n" "$2" >"$1"' sh "$CTL" "$*"

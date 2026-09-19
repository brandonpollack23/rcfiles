#!/bin/sh
# System commands: session, restarts and maintenance.
#   system.sh            pick any command in hyprlauncher (SUPER+SHIFT+R)
#   system.sh power      pick from the power commands (waybar power button)
#   system.sh <action>   run one command, e.g. system.sh restart-waybar

# "action|label" per line; the label is what the picker shows.
POWER='lock|󰌾  Lock
logout|󰍃  Log out
suspend|󰤄  Suspend
reboot|󰜉  Reboot
poweroff|󰐥  Shut down'

ALL="$POWER
reload-hyprland|󰑓  Reload Hyprland config
restart-waybar|󰑓  Restart waybar
reload-swaync|󰑓  Reload notification center config and style
restart-swaync|󰑓  Restart notification center
restart-ydotool|󰑓  Restart ydotool (notification center keys)
restart-audio|󰑓  Restart audio (PipeWire)
update|󰚰  Update system (paru)
clean|󰃢  Remove unneeded packages (paru)
failed-units|󰀦  Failed services
journal-errors|󰀦  Errors since boot"

# Runs a command in a terminal that stays open so the output can be read.
in_terminal() {
	ghostty --wait-after-command=true -e "$@"
}

pick() {
	label=$(printf '%s\n' "$1" | cut -d'|' -f2 | hyprlauncher --dmenu)
	test -n "$label" || exit 0
	printf '%s\n' "$1" | grep -F "|$label" | cut -d'|' -f1
}

action=$1
case "$action" in
"") action=$(pick "$ALL") ;;
power) action=$(pick "$POWER") ;;
esac

case "$action" in
lock) pidof hyprlock || hyprlock ;;
logout) hyprctl dispatch 'hl.dsp.exit()' ;;
suspend) systemctl suspend ;;
reboot) systemctl reboot ;;
poweroff) systemctl poweroff ;;

reload-hyprland) hyprctl reload ;;
restart-waybar)
	pkill -x waybar
	setsid -f waybar >/dev/null 2>&1
	;;
reload-swaync) swaync-client -R && swaync-client -rs ;;
restart-swaync)
	# Wait for the old daemon to release its D-Bus name, or the new one exits
	# with "already running".
	pkill -x swaync
	while pgrep -x swaync >/dev/null; do sleep 0.1; done
	setsid -f swaync >/dev/null 2>&1
	;;
restart-ydotool) systemctl --user restart ydotool ;;
restart-audio) systemctl --user restart wireplumber pipewire pipewire-pulse ;;

update) in_terminal paru -Syu ;;
clean) in_terminal paru -c ;;
failed-units) in_terminal systemctl --failed ;;
journal-errors) in_terminal journalctl -b -p err --no-pager ;;

*)
	echo "usage: $0 [power | <action>]" >&2
	exit 1
	;;
esac

#!/bin/sh
# Power menu for the power button (custom/power in config.jsonc), picked
# in hyprlauncher like the scripts in the hypr config.
choice=$(printf '%s\n' \
	"󰌾  Lock" \
	"󰍃  Log out" \
	"󰤄  Suspend" \
	"󰜉  Reboot" \
	"󰐥  Shut down" |
	hyprlauncher --dmenu)

case "$choice" in
*Lock) pidof hyprlock || hyprlock ;;
*"Log out") hyprctl dispatch 'hl.dsp.exit()' ;;
*Suspend) systemctl suspend ;;
*Reboot) systemctl reboot ;;
*"Shut down") systemctl poweroff ;;
esac

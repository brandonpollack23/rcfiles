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
restart-hypridle|󰑓  Restart hypridle (idle dim, lock, screens off)
restart-hypr-persist|󰑓  Restart hypr-persist (session restore)
session-save|󰆓  Save session now (hypr-persist)
restart-audio|󰑓  Restart audio (PipeWire)
enroll-fingerprint|󰈷  Enroll fingerprint (fprintd)
update|󰚰  Update system (paru)
clean|󰃢  Remove unneeded packages (paru)
failed-units|󰀦  Failed services
journal-errors|󰀦  Errors since boot
restart-awww|󰑓  Restart wallpaper daemon (awww)
bing-update|󰸉  Refresh Bing wallpaper
bing-frequency|󰸉  Bing wallpaper update frequency
fcitx5-configtool|⌨️ IME Input Configurator (Mozc)"

# Only listed once the wallpaper script has saved the image's metadata.
bing_title=$(~/.config/hypr/scripts/bing-wallpaper.sh title)
test -n "$bing_title" && ALL="$ALL
bing-open|󰖟  Bing Wallpaper: $bing_title"

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
restart-hypridle)
  pkill -x hypridle
  while pgrep -x hypridle >/dev/null; do sleep 0.1; done
  setsid -f hypridle >/dev/null 2>&1
  ;;
restart-hypr-persist)
  pkill -x hypr-persist
  while pgrep -x hypr-persist >/dev/null; do sleep 0.1; done
  setsid -f hypr-persist >/dev/null 2>&1
  ;;
session-save) hypr-persist save ;;
restart-audio) systemctl --user restart wireplumber pipewire pipewire-pulse ;;
enroll-fingerprint) in_terminal sh -c 'fprintd-enroll && fprintd-verify' ;;

update) in_terminal paru -Syu ;;
clean) in_terminal paru -c ;;
failed-units) in_terminal systemctl --failed ;;
journal-errors) in_terminal journalctl -b -p err --no-pager ;;

restart-awww)
  pkill -x awww-daemon
  while pgrep -x awww-daemon >/dev/null; do sleep 0.1; done
  setsid -f awww-daemon >/dev/null 2>&1
  ~/.config/hypr/scripts/bing-wallpaper.sh refresh
  ;;
bing-update) ~/.config/hypr/scripts/bing-wallpaper.sh refresh ;;
bing-open) ~/.config/hypr/scripts/bing-wallpaper.sh open ;;
bing-frequency)
  frequency=$(printf 'hourly\ndaily\nweekly\n' | hyprlauncher --dmenu)
  test -n "$frequency" && ~/.config/hypr/scripts/bing-wallpaper.sh frequency "$frequency"
  ;;

fcitx5-configtool) fcitx5-configtool ;;

*)
  echo "usage: $0 [power | <action>]" >&2
  exit 1
  ;;
esac

#!/bin/bash

# Unlock the Omarchy lock screen from an SSH or mosh session, without a remote
# viewer: wake the display, then type the password into the lock's field with
# wtype (a virtual keyboard, which the lock accepts like a real one).
#
#   remote-screen-unlock.sh          prompt for the password, unlock
#   remote-screen-unlock.sh --wake   only turn the display back on
#
# A remote shell has none of the session's Wayland or Hyprland variables, so
# they are found from the runtime directory. The password is read hidden and
# piped to wtype's stdin, so it never appears on a command line or in history.

set -euo pipefail

# The lock swallows the first keys while it wakes from blank or screensaver.
WAKE_SECONDS=3
# How long PAM gets to check the password before we report.
CHECK_SECONDS=10

die() {
  echo "remote-screen-unlock: $*" >&2
  exit 1
}

find_session() {
  export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

  if [[ -z ${WAYLAND_DISPLAY:-} ]]; then
    local socket
    for socket in "$XDG_RUNTIME_DIR"/wayland-*; do
      [[ -S $socket ]] && { WAYLAND_DISPLAY=${socket##*/}; break; }
    done
    [[ -n ${WAYLAND_DISPLAY:-} ]] || die "no Wayland socket in $XDG_RUNTIME_DIR; is Hyprland running?"
    export WAYLAND_DISPLAY
  fi

  if [[ -z ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
    # The newest instance, in case an old one left its directory behind.
    HYPRLAND_INSTANCE_SIGNATURE=$(ls -t "$XDG_RUNTIME_DIR/hypr" 2>/dev/null | head -1)
    [[ -n $HYPRLAND_INSTANCE_SIGNATURE ]] || die "no Hyprland instance in $XDG_RUNTIME_DIR/hypr"
    export HYPRLAND_INSTANCE_SIGNATURE
  fi
}

wake_display() {
  hyprctl dispatch 'hl.dsp.dpms({ action = "on" })' >/dev/null
}

is_locked() {
  [[ $(omarchy-shell lock isLocked 2>/dev/null) == true ]]
}

unlock() {
  [[ -t 0 ]] || die "needs a terminal to read the password from"

  local password
  read -rsp "Password: " password
  echo
  [[ -n $password ]] || die "no password given"

  wake_display
  # Escape both wakes the lock and clears anything already in its field.
  wtype -k Escape
  sleep "$WAKE_SECONDS"

  printf '%s' "$password" | wtype -
  unset password
  wtype -k Return

  local waited=0
  while is_locked && ((waited < CHECK_SECONDS)); do
    sleep 1
    waited=$((waited + 1))
  done

  if is_locked; then
    die "still locked: wrong password, or the keys didn't reach the field (omarchy-shell lock status shows the last event)"
  fi
  echo "Unlocked."
}

main() {
  for cmd in hyprctl wtype omarchy-shell; do
    command -v "$cmd" >/dev/null || die "$cmd not found"
  done
  find_session

  case "${1:-}" in
    --wake)
      wake_display
      echo "Display on."
      ;;
    "")
      if is_locked; then
        unlock
      else
        wake_display
        echo "Not locked; display on."
      fi
      ;;
    -h | --help)
      sed -n '3,12p' "$0" | sed 's/^# \{0,1\}//'
      ;;
    *)
      die "unknown argument: $1 (try --help)"
      ;;
  esac
}

main "$@"

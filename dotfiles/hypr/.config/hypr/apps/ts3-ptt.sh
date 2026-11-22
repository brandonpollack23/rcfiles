#!/usr/bin/env bash
# Push-to-talk for TeamSpeak 3 through its ClientQuery plugin, which does
# what TS3's own push-to-talk does: `on` turns the capture device on, `off`
# turns it off, on the server tab that's selected in TS3. Bound in ts3.lua.
# The API key is TS3's own, read from its config each time, never stored here.
set -u

case ${1:-} in
  on) deactivated=0 ;;
  off) deactivated=1 ;;
  *) echo "usage: ts3-ptt.sh on|off" >&2; exit 2 ;;
esac

key=$(sed -n 's/^api_key=//p' "$HOME/.ts3client/clientquery.ini")

# A quick click starts the release's run before the press's has finished;
# the lock keeps them in order, so a release never lands first and leaves the
# mic on.
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/ts3-ptt.lock"
flock 9

exec 3<>/dev/tcp/127.0.0.1/25639 || exit 1
printf 'auth apikey=%s\nclientupdate client_input_deactivated=%s\nquit\n' "$key" "$deactivated" >&3
timeout 1 cat <&3 >/dev/null

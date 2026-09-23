#!/usr/bin/env bash
#deleteme
# Opens Steam's install dialog for each app in steam-appids.txt, one at a
# time, and waits until Steam has queued it (its appmanifest shows up) before
# opening the next. If the dialog shows up as its own window, it is focused
# and sent Enter once; otherwise click Install yourself. Press Enter in this
# terminal to skip an app (e.g. after cancelling its dialog).
# Already-installed apps are skipped.

steam_root="$HOME/.local/share/Steam"

library_dirs() {
  sed -n 's/^[[:space:]]*"path"[[:space:]]*"\(.*\)"$/\1/p' \
    "$steam_root/steamapps/libraryfolders.vdf" 2>/dev/null
  echo "$steam_root"
}

installed() {
  local dir
  while read -r dir; do
    [ -e "$dir/steamapps/appmanifest_$1.acf" ] && return 0
  done < <(library_dirs)
  return 1
}

steam_windows() {
  hyprctl clients -j |
    jq -r '.[] | select(.class == "steam" and .mapped and (.hidden | not)) | "\(.address) \(.title)"' |
    sort
}

before=$(mktemp)
trap 'rm -f "$before"' EXIT

mapfile -t appids <steam-appids.txt

for appid in "${appids[@]}"; do
  [ -z "$appid" ] && continue
  if installed "$appid"; then
    echo "$appid: already installed, skipping"
    continue
  fi

  steam_windows >"$before"
  steam "steam://install/$appid" </dev/null >/dev/null 2>&1 &
  echo "$appid: waiting for install to be queued (Enter here to skip)..."

  pressed=
  while ! installed "$appid"; do
    if [ -z "$pressed" ]; then
      dialog=$(steam_windows | comm -13 "$before" - | head -n1)
      if [ -n "$dialog" ]; then
        echo "$appid: dialog window '${dialog#* }', pressing Enter"
        hyprctl dispatch focuswindow "address:${dialog%% *}" >/dev/null
        sleep 0.5
        wtype -k Return
        pressed=1
      fi
    fi
    if read -r -t 0.5 </dev/tty; then
      echo "$appid: skipped"
      continue 2
    fi
  done
  echo "$appid: queued"
done

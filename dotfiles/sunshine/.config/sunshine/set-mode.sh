#!/bin/sh
# Sunshine prep-cmd for Hyprland: streams a virtual monitor at the Moonlight
# client's resolution and refresh rate, since a physical monitor only takes
# the modes in its EDID. On connect it creates a headless output in that mode
# and turns the physical monitors off, which moves their workspaces to it,
# windows and all. Sunshine captures the first monitor Hyprland lists (with no
# output_name in sunshine.conf), which is then the headless one.
#
# The monitor rules go in $rules, which hypr/hyprland.lua loads, so a config
# reload keeps them: without that, a reload (saving a layout choice does one)
# turns the physical monitors back on and takes the workspaces off the stream.
#
# "restore" turns the monitors back on before removing the headless output, so
# the workspaces go back to them, and refocuses the workspace that was active.
# That workspace and the monitors' modes are saved in $state.
#
# If Sunshine never runs the undo, the screen stays off: run this with
# "restore" over SSH.
set -eu
headless=SUNSHINE
state="${XDG_RUNTIME_DIR:-/tmp}/sunshine-monitors"
rules="${XDG_RUNTIME_DIR:-/tmp}/sunshine-monitors.lua"

# monitor <the fields of an hl.monitor rule, in Lua>
monitor() {
  hyprctl eval "hl.monitor({ $1 })" > /dev/null
}

focus_workspace() {
  hyprctl eval "hl.dispatch(hl.dsp.focus({ workspace = $1 }))" > /dev/null
}

# Monitor rules take effect a moment after they're sent, and a workspace
# focused before then is on the wrong monitor once they do. Wait (up to 5s)
# until the physical monitors saved in $state are all <on|off>.
wait_monitors() {
  names=$(tail -n +2 "$state" | cut -d ' ' -f 1 | jq -R . | jq -s -c .)
  tries=0
  while [ "$tries" -lt 50 ]; do
    if hyprctl monitors -j | jq -e --argjson names "$names" --arg want "$1" \
      '[.[] | select(.name | IN($names[]))] | length == (if $want == "on" then ($names | length) else 0 end)' > /dev/null; then
      return
    fi
    sleep 0.1
    tries=$((tries + 1))
  done
}

if [ "${1:-}" = restore ]; then
  rm -f "$rules"
  workspace=
  if [ -f "$state" ]; then
    workspace=$(head -n 1 "$state")
    tail -n +2 "$state" | while read -r name mode position scale transform; do
      monitor "output = '$name', mode = '$mode', position = '$position', scale = $scale, transform = $transform"
    done
    wait_monitors on
  fi
  hyprctl output remove "$headless" > /dev/null || true
  [ -n "$workspace" ] && focus_workspace "$workspace"
  rm -f "$state"
  exit
fi

# Line 1 is the active workspace, then one line per physical monitor. A second
# connect before the undo keeps what the first saved and only changes the
# headless output's mode.
if [ ! -f "$state" ]; then
  {
    hyprctl activeworkspace -j | jq -r .id
    hyprctl monitors -j | jq -r --arg h "$headless" '.[] | select(.name != $h) | "\(.name) \(.width)x\(.height)@\(.refreshRate) \(.x)x\(.y) \(.scale) \(.transform)"'
  } > "$state"
fi
if ! hyprctl monitors -j | jq -e --arg h "$headless" 'any(.name == $h)' > /dev/null; then
  hyprctl output create headless "$headless" > /dev/null
fi

# High-resolution clients (a Mac's Retina screen) get scale 2, as they show it.
scale=1
[ "$SUNSHINE_CLIENT_HEIGHT" -ge 1440 ] && scale=2
{
  echo "hl.monitor({ output = '$headless', mode = '${SUNSHINE_CLIENT_WIDTH}x${SUNSHINE_CLIENT_HEIGHT}@${SUNSHINE_CLIENT_FPS}', position = 'auto', scale = $scale })"
  tail -n +2 "$state" | while read -r name _; do
    echo "hl.monitor({ output = '$name', disabled = true })"
  done
} > "$rules"
hyprctl eval "dofile('$rules')" > /dev/null

# The new headless output came with an empty workspace of its own. Focusing
# the saved one once the physical monitors are gone, and so it's on the
# headless output too, shows it there in place of the empty one, which closes.
wait_monitors off
focus_workspace "$(head -n 1 "$state")"

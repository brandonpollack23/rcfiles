#!/bin/sh
# Sunshine prep-cmd for Hyprland: streams a virtual monitor at the Moonlight
# client's resolution and refresh rate, since a physical monitor only takes
# the modes in its EDID. On connect it creates a headless output in that mode
# and turns the physical monitors off, which moves their workspaces to it,
# windows and all. Sunshine captures the first monitor Hyprland lists (with no
# output_name in sunshine.conf), which is then the headless one.
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

# monitor <the fields of an hl.monitor rule, in Lua>
monitor() {
  hyprctl eval "hl.monitor({ $1 })" > /dev/null
}

focus_workspace() {
  hyprctl eval "hl.dispatch(hl.dsp.focus({ workspace = $1 }))" > /dev/null
}

if [ "${1:-}" = restore ]; then
  workspace=
  if [ -f "$state" ]; then
    workspace=$(head -n 1 "$state")
    tail -n +2 "$state" | while read -r name mode position scale transform; do
      monitor "output = '$name', mode = '$mode', position = '$position', scale = $scale, transform = $transform"
    done
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
monitor "output = '$headless', mode = '${SUNSHINE_CLIENT_WIDTH}x${SUNSHINE_CLIENT_HEIGHT}@${SUNSHINE_CLIENT_FPS}', position = 'auto', scale = $scale"

tail -n +2 "$state" | while read -r name _; do
  monitor "output = '$name', disabled = true"
done
focus_workspace "$(head -n 1 "$state")"

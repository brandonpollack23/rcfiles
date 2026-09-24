#!/bin/sh
# Sunshine prep-cmd for Hyprland: switches the main monitor to the Moonlight
# client's resolution and refresh rate, and back with "restore". The main
# monitor is the first one Hyprland lists, which is the one Sunshine captures
# unless sunshine.conf sets output_name. Its mode before the stream is saved
# in $state so restore puts back exactly that.
set -eu
state="${XDG_RUNTIME_DIR:-/tmp}/sunshine-monitor"

# monitor <name> <mode> <position> <scale> <transform>
monitor() {
  hyprctl eval "hl.monitor({ output = '$1', mode = '$2', position = '$3', scale = $4, transform = $5 })"
}

if [ "${1:-}" = restore ]; then
  [ -f "$state" ] || exit 0
  read -r name mode position scale transform < "$state"
  rm -f "$state"
  monitor "$name" "$mode" "$position" "$scale" "$transform"
  exit
fi

# A second connect before the undo keeps the mode saved by the first.
if [ ! -f "$state" ]; then
  hyprctl monitors -j | jq -r '.[0] | "\(.name) \(.width)x\(.height)@\(.refreshRate) \(.x)x\(.y) \(.scale) \(.transform)"' > "$state"
fi
read -r name _ position _ _ < "$state"
monitor "$name" "${SUNSHINE_CLIENT_WIDTH}x${SUNSHINE_CLIENT_HEIGHT}@${SUNSHINE_CLIENT_FPS}" "$position" 1 0

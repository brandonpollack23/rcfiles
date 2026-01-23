#!/usr/bin/env bash
# Toggle between center layout and right-oriented "coding with reference" layout

current=$(hyprctl getoption master:orientation -j | jq -r '.str')

if [[ "$current" == "right" ]]; then
    hyprctl keyword master:orientation center
    hyprctl keyword master:mfact 0.5
else
    hyprctl keyword master:orientation right
    hyprctl keyword master:mfact 0.7
fi

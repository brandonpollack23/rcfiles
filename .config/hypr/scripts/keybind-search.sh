#!/bin/sh
# Fuzzy-search keybindings (keys, description, command) in hyprlauncher and run
# the picked one. The list comes from the registry in conf/keymaps.lua.
choice=$(hyprctl repl 'return require("conf.keymaps").menu()' | hyprlauncher --dmenu)
test -n "$choice" || exit 0
hyprctl repl "require('conf.keymaps').run([==[$choice]==])" >/dev/null

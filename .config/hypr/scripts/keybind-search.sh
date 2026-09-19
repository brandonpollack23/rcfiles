#!/bin/sh
# Fuzzy-search keybindings (keys, description, command) in hyprlauncher and run
# the picked one. The list comes from the registry in conf/bind_helpers.lua.
choice=$(hyprctl repl 'return require("conf.bind_helpers").menu()' | hyprlauncher --dmenu)
test -n "$choice" || exit 0
hyprctl repl "require('conf.bind_helpers').run([==[$choice]==])" >/dev/null

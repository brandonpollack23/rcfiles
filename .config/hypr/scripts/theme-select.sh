#!/bin/sh
# Pick a theme from conf/themes/ in hyprlauncher and switch to it (conf/theme.lua).
choice=$(hyprctl repl 'return require("conf.theme").menu()' | hyprlauncher --dmenu)
test -n "$choice" || exit 0
hyprctl repl "require('conf.theme').select([==[$choice]==])" >/dev/null

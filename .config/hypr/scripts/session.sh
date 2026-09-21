#!/bin/sh
# Session restore at login, then the hypr-persist daemon.
#
# hypr-persist replays workspaces by name, which named workspaces break (see
# conf/workspaces/persist.lua), so the daemon's own restore_on_start is off and
# the restore runs here instead, on the id-addressed copy the config wrote as
# session "boot". `restore` blocks until the slow starters are placed too.

if test "$1" = restore; then
	hypr-persist restore boot
	hyprctl eval 'require("conf.workspaces").finishRestore()' >/dev/null
fi

exec hypr-persist

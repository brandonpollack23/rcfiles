#!/bin/sh
# Workspace picker and naming prompts; the logic lives in conf/workspaces.lua.
#   focus   pick a workspace (or create one) in hyprlauncher and go there
#   move    same, but send the active window there
#   new     name and place a new workspace and go there
#   rename  rename the active workspace
ws='require("conf.workspaces")'

# The entry text starts selected, so typing replaces the suggestion.
ask() {
	zenity --entry --title "$1" --text "$2" --entry-text "$3"
}

# The first row is the default; OK with nothing selected also means it.
place() {
	hyprctl repl "return $ws.positions()" |
		zenity --list --title 'New workspace' --text 'Put it:' \
			--column Position --hide-header
}

create() {
	name=$(ask 'New workspace' 'Name:' "$2") || exit 0
	position=$(place) || exit 0
	hyprctl eval "$ws.create('$1', [==[$name]==], [==[$position]==])" >/dev/null
}

case $1 in
focus | move)
	choice=$(hyprctl repl "return $ws.menu()" | hyprlauncher --dmenu)
	test -n "$choice" || exit 0
	suggested=$(hyprctl repl "return $ws.pick('$1', [==[$choice]==])")
	test "$suggested" = true || create "$1" "$suggested"
	;;
new)
	create focus "$(hyprctl repl "return $ws.newName()")"
	;;
rename)
	active=$(hyprctl repl "return $ws.active()")
	id=${active%%
*}
	name=$(ask 'Rename workspace' "Workspace $id:" "${active#*
}") || exit 0
	hyprctl eval "$ws.rename($id, [==[$name]==])" >/dev/null
	;;
*)
	echo "usage: $0 focus|move|new|rename" >&2
	exit 2
	;;
esac

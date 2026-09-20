#!/bin/sh
# Workspace picker and naming prompts; the logic lives in conf/workspaces/.
#   focus   pick a workspace (or create one) in hyprlauncher and go there
#   move    same, but send the active window there
#   new     name and place a new workspace and go there
#   rename  rename the active workspace
#   move-hidden  send the active window to a hidden workspace, picking one only
#                when there is more than the default to pick from
# The picker also lists the hidden workspaces as H1, H2, ... and offers a row
# for a new one; those take a name but no placement.
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

createHidden() {
	name=$(ask 'New hidden workspace' 'Name:' '') || exit 0
	hyprctl eval "$ws.createHidden('$1', [==[$name]==])" >/dev/null
}

case $1 in
focus | move)
	choice=$(hyprctl repl "return $ws.menu()" | hyprlauncher --dmenu)
	test -n "$choice" || exit 0
	# "done", or a create verb with the suggested name on the second line.
	result=$(hyprctl repl "return $ws.pick('$1', [==[$choice]==])")
	case ${result%%
*} in
	new)
		create "$1" "${result#*
}"
		;;
	hidden)
		createHidden "$1"
		;;
	esac
	;;
move-hidden)
	# With only the default one around there is nothing to pick from.
	choice=
	if test "$(hyprctl repl "return $ws.hiddenCount()")" -gt 0; then
		choice=$(hyprctl repl "return $ws.hiddenMenu()" | hyprlauncher --dmenu)
		test -n "$choice" || exit 0
	fi
	if test "$(hyprctl repl "return $ws.moveToHidden([==[$choice]==])")" = hidden; then
		createHidden move
	fi
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
	echo "usage: $0 focus|move|move-hidden|new|rename" >&2
	exit 2
	;;
esac

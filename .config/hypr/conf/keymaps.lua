local programs = require("conf.programs")
local wm = require("conf.wm")
local helpers = require("conf.bind_helpers")
local theme = require("conf.theme")
local workspaces = require("conf.workspaces")

local bind, bindExec, bindLayout = helpers.bind, helpers.bindExec, helpers.bindLayout

local mainMod = "SUPER" -- Sets "Windows" key as main modifier

-- Move focus with mainMod + vim motions
bind(
	mainMod .. " + h",
	hl.dsp.focus({ direction = "left" }),
	{ description = "Focus window left", command = "focus left" }
)
bind(
	mainMod .. " + j",
	hl.dsp.focus({ direction = "down" }),
	{ description = "Focus window down", command = "focus down" }
)
bind(mainMod .. " + k", hl.dsp.focus({ direction = "up" }), { description = "Focus window up", command = "focus up" })
bind(
	mainMod .. " + l",
	hl.dsp.focus({ direction = "right" }),
	{ description = "Focus window right", command = "focus right" }
)

-- Closing windows
bind(mainMod .. " + Q", hl.dsp.window.close(), { description = "Close Window", command = "window.close" })
bind(
	mainMod .. " + SHIFT + Q",
	wm.closeOtherWindows,
	{ description = "Close all windows except focused group", command = "wm.closeOtherWindows" }
)

-- Grouping
bind(mainMod .. " + G", wm.toggleGroup, { description = "Toggle window group", command = "wm.toggleGroup" })
bind(mainMod .. " + SHIFT + G", wm.toggleGroupLock, {
	description = "Toggle whether the active group is 'locked' (new windows dont open in it)",
	command = "wm.toggleGroupLock",
})
bind(mainMod .. " + TAB", hl.dsp.group.next(), { description = "Next window in group", command = "group.next" })
bind(
	mainMod .. " + SHIFT + TAB",
	hl.dsp.group.prev(),
	{ description = "Previous window in group", command = "group.prev" }
)

-- Joining a group takes a direction, and reordering tabs is repetitive, so both
-- get a submap: the first key opens it, and Escape (or any unbound key) leaves.
local groupSubmapKey = mainMod .. " + ALT + G"
local reorderSubmapKey = mainMod .. " + CTRL + G"

hl.define_submap("group", function()
	for _, entry in ipairs({ { "h", "left" }, { "j", "down" }, { "k", "up" }, { "l", "right" } }) do
		local key, direction = entry[1], entry[2]
		bind(key, function()
			wm.groupWith(direction)
			hl.dispatch(hl.dsp.submap("reset"))
		end, {
			prefix = groupSubmapKey,
			description = "Group with the window or group to the " .. direction,
			command = "wm.groupWith " .. direction,
		})
	end
	bind("Escape", hl.dsp.submap("reset"), {
		prefix = groupSubmapKey,
		description = "Cancel grouping",
		command = "submap reset",
	})
	hl.bind("catchall", hl.dsp.submap("reset"))
end)
bind(groupSubmapKey, hl.dsp.submap("group"), {
	description = "Group with a neighbour, then h/j/k/l for the direction",
	command = "submap group",
})
bind(mainMod .. " + ALT + SHIFT + G", wm.ungroup, {
	description = "Move the window out of its group, leaving the group intact",
	command = "wm.ungroup",
})

-- Unlike the grouping submap this one stays open, so tabs can be walked along
-- with repeated h/l.
hl.define_submap("group-reorder", function()
	bind("h", function()
		wm.moveInGroup(false)
	end, {
		prefix = reorderSubmapKey,
		repeating = true,
		description = "Move the window earlier in its group",
		command = "wm.moveInGroup back",
	})
	bind("l", function()
		wm.moveInGroup(true)
	end, {
		prefix = reorderSubmapKey,
		repeating = true,
		description = "Move the window later in its group",
		command = "wm.moveInGroup forward",
	})
	bind("Escape", hl.dsp.submap("reset"), {
		prefix = reorderSubmapKey,
		description = "Finish reordering",
		command = "submap reset",
	})
	hl.bind("catchall", hl.dsp.submap("reset"))
end)
bind(reorderSubmapKey, hl.dsp.submap("group-reorder"), {
	description = "Reorder tabs in the group, then h/l, Escape to finish",
	command = "submap group-reorder",
})

-- Undo/redo for the group actions above, see conf/wm/. Only covers what goes
-- through these binds: Hyprland fires no event for grouping done by mouse.
bind(mainMod .. " + CTRL + Z", wm.undo, { description = "Undo the last group change", command = "wm.undo" })
bind(mainMod .. " + CTRL + SHIFT + Z", wm.redo, {
	description = "Redo the last undone group change",
	command = "wm.redo",
})

-- Window manipulation (floating, pseudo, splitting, etc)
bind(
	mainMod .. " + v",
	hl.dsp.window.float({ action = "toggle" }),
	{ description = "Toggle floating", command = "window.float toggle" }
)
bind(mainMod .. " + p", hl.dsp.window.pseudo(), { description = "Toggle pseudotile", command = "window.pseudo" })
-- Move/resize windows with mainMod + LMB/RMB and dragging
bind(
	mainMod .. " + mouse:272",
	hl.dsp.window.drag(),
	{ mouse = true, description = "Drag window (left mouse)", command = "window.drag" }
)
bind(
	mainMod .. " + mouse:273",
	hl.dsp.window.resize(),
	{ mouse = true, description = "Resize window (right mouse)", command = "window.resize" }
)

-- Application launches
bindExec(mainMod .. " + r", programs.menu, { description = "App launcher" })
bindExec(mainMod .. " + T", programs.terminal, { description = "Terminal" })
bindExec(mainMod .. " + e", programs.fileManager, { description = "File manager" })
bindExec(mainMod .. " + SHIFT + Escape", "pidof hyprlock || " .. programs.lock, { description = "Lock screen" })
bindExec(
	mainMod .. " + SHIFT + r",
	"~/.config/hypr/scripts/system.sh",
	{ description = "System commands (restart, power, maintenance)" }
)
bindExec(mainMod .. " + slash", "~/.config/hypr/scripts/keybind-search.sh", { description = "Search keybindings" })
bindExec(mainMod .. " + semicolon", programs.emoji, { description = "Pick an emoji" })
bindExec(mainMod .. " + N", "swaync-client -t -sw", { description = "Toggle notification center" })
bindExec(mainMod .. " + SHIFT + N", "swaync-client --hide-all -sw", { description = "Dismiss all notification popups" })

-- Theming, see conf/theme/
bindExec(mainMod .. " + F5", "~/.config/hypr/scripts/theme-select.sh", { description = "Pick a theme" })
bind(mainMod .. " + F6", function()
	theme.cycle(1)
end, { description = "Next theme", command = "theme.cycle 1" })
bind(mainMod .. " + SHIFT + F6", function()
	theme.cycle(-1)
end, { description = "Previous theme", command = "theme.cycle -1" })

-- Workspaces, see conf/workspaces/
-- Switch workspaces with mainMod + [0-9]
for i = 1, 10 do
	local key = i % 10 -- 10 maps to key 0
	bind(
		mainMod .. " + " .. key,
		hl.dsp.focus({ workspace = i }),
		{ description = "Go to workspace " .. i, command = "focus workspace " .. i }
	)
end

local workspaceMenu = "~/.config/hypr/scripts/workspace-menu.sh"
bindExec(mainMod .. " + W", workspaceMenu .. " focus", { description = "Pick a workspace (or create one)" })
bindExec(mainMod .. " + SHIFT + W", workspaceMenu .. " new", { description = "Create a named workspace" })
bindExec(mainMod .. " + M", workspaceMenu .. " move", { description = "Move window to a picked workspace" })
-- mainMod + "$": binds match the unshifted key, so "dollar" never fires
bindExec(mainMod .. " + SHIFT + 4", workspaceMenu .. " rename", { description = "Rename workspace" })

-- The default hidden workspace. The others are named, and are reached through
-- the picker (conf/workspaces/hidden.lua) and their waybar buttons.
bind(mainMod .. " + S", function()
	workspaces.toggleHidden()
end, { description = "Put away the open hidden workspace, or raise the scratchpad", command = "workspaces.toggleHidden" })
bindExec(
	mainMod .. " + SHIFT + S",
	workspaceMenu .. " move-hidden",
	{ description = "Move window to a hidden workspace" }
)

-- Scroll through existing workspaces with mainMod + scroll
bind(
	mainMod .. " + mouse_down",
	hl.dsp.focus({ workspace = "e+1" }),
	{ description = "Next workspace (scroll)", command = "focus workspace e+1" }
)
bind(
	mainMod .. " + mouse_up",
	hl.dsp.focus({ workspace = "e-1" }),
	{ description = "Previous workspace (scroll)", command = "focus workspace e-1" }
)

-- Cycle through existing workspaces with mainMod + SHIFT + left/right (wraps around)
bind(
	mainMod .. " + CTRL + right",
	hl.dsp.focus({ workspace = "e+1" }),
	{ description = "Next workspace", command = "focus workspace e+1" }
)
bind(
	mainMod .. " + CTRL + left",
	hl.dsp.focus({ workspace = "e-1" }),
	{ description = "Previous workspace", command = "focus workspace e-1" }
)

-- Reorder workspaces: swap the active one with its neighbour, see conf/workspaces/
bind(mainMod .. " + CTRL + SHIFT + right", function()
	workspaces.shift(1)
end, { description = "Move workspace right", command = "workspaces.shift 1" })
bind(mainMod .. " + CTRL + SHIFT + left", function()
	workspaces.shift(-1)
end, { description = "Move workspace left", command = "workspaces.shift -1" })

-- Master layout, see https://wiki.hypr.land/configuring/layouts/master-layout/
bindLayout(mainMod .. " + Return", "swapwithmaster", "Promote window to master")
bindLayout(mainMod .. " + SHIFT + Return", "focusmaster", "Focus master window")
bindLayout(mainMod .. " + I", "addmaster", "Add window as a master")
bindLayout(mainMod .. " + D", "removemaster", "Remove window from masters")
bindLayout(mainMod .. " + O", "orientationcycle left top right bottom center", "Cycle master orientation")

-- Multimedia and brightness control control

-- Laptop multimedia keys for volume and LCD brightness
-- Each bind then shows the new level in SwayOSD, which cannot pick these keys up
-- by itself (scripts/osd.sh).
local osd = "~/.config/hypr/scripts/osd.sh"
bindExec(
	"XF86AudioRaiseVolume",
	"wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+; " .. osd .. " sink",
	{ locked = true, repeating = true, description = "Volume up" }
)
bindExec(
	"XF86AudioLowerVolume",
	"wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-; " .. osd .. " sink",
	{ locked = true, repeating = true, description = "Volume down" }
)
bindExec(
	"XF86AudioMute",
	"wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle; " .. osd .. " sink",
	{ locked = true, repeating = true, description = "Mute audio" }
)
bindExec(
	"XF86AudioMicMute",
	"wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle; " .. osd .. " source",
	{ locked = true, repeating = true, description = "Mute microphone" }
)

-- Requires playerctl
bindExec("XF86AudioNext", "playerctl next", { locked = true, description = "Next track" })
bindExec("XF86AudioPause", "playerctl play-pause", { locked = true, description = "Play/pause" })
bindExec("XF86AudioPlay", "playerctl play-pause", { locked = true, description = "Play/pause" })
bindExec("XF86AudioPrev", "playerctl previous", { locked = true, description = "Previous track" })

bindExec(
	"XF86MonBrightnessUp",
	"brightnessctl -e4 -n2 set 5%+; " .. osd .. " brightness",
	{ locked = true, repeating = true, description = "Brightness up" }
)
bindExec(
	"XF86MonBrightnessDown",
	"brightnessctl -e4 -n2 set 5%-; " .. osd .. " brightness",
	{ locked = true, repeating = true, description = "Brightness down" }
)

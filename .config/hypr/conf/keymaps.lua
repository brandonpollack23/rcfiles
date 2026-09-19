local programs = require("conf.programs")
local wm = require("conf.wm")

local mainMod = "SUPER" -- Sets "Windows" key as main modifier

-- Move focus with mainMod + vim motions
hl.bind(mainMod .. " + h", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + j", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + k", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + l", hl.dsp.focus({ direction = "right" }))

-- Closing windows
local closeWindowBind = hl.bind(mainMod .. " + Q", hl.dsp.window.close(), { description = "Close Window" })
hl.bind(mainMode .. "+ SHIFT + Q", wm.closeOtherWindows(), { description = "Close all windows except focused group" })
-- closeWindowBind:set_enabled(false)

-- Grouping
-- TODO ungroup keep current focus as master
hl.bind(mainMod .. " + G", hl.dsp.group.toggle(), { description = "Toggle window group" })
hl.bind(
	mainMod .. " + SHIFT + G",
	hl.dsp.group.lock_active(),
	{ description = "Toggle whether the active group is 'locked' (new windows dont open in it)" }
)
hl.bind("ALT + TAB", hl.dsp.group.next(), { description = "Next window in group" })
hl.bind("ALT + SHIFT + TAB", hl.dsp.group.prev(), { description = "Previous window in group" })

-- Window manipulation (floating, pseudo, splitting, etc)
hl.bind(mainMod .. " + v", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + p", hl.dsp.window.pseudo())
-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
-- hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit")) -- dwindle only

-- Application launches
hl.bind(mainMod .. " + r", hl.dsp.exec_cmd(programs.menu))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(programs.terminal))
hl.bind(mainMod .. " + e", hl.dsp.exec_cmd(programs.fileManager))

-- Workspaces
-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
	local key = i % 10 -- 10 maps to key 0
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Example special workspace (scratchpad)
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Cycle through existing workspaces with mainMod + SHIFT + left/right (wraps around)
hl.bind(mainMod .. " + CTRL + right", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + CTRL + left", hl.dsp.focus({ workspace = "e-1" }))

-- Master layout, see https://wiki.hypr.land/configuring/layouts/master-layout/
hl.bind(mainMod .. " + Return", hl.dsp.layout("swapwithmaster")) -- promote focused window to master
hl.bind(mainMod .. " + SHIFT + Return", hl.dsp.layout("focusmaster"))
hl.bind(mainMod .. " + I", hl.dsp.layout("addmaster")) -- focused window becomes an additional master
hl.bind(mainMod .. " + D", hl.dsp.layout("removemaster"))
hl.bind(mainMod .. " + O", hl.dsp.layout("orientationcycle left top right bottom center"))

-- Shutdown/logout
-- hl.bind(
-- 	mainMod .. " + M",
-- 	hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'")
-- )

-- Multimedia and brightness control control

-- Laptop multimedia keys for volume and LCD brightness
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
	{ locked = true, repeating = true }
)

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

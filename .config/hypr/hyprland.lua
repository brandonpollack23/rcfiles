-- Refer to the wiki for more information: https://wiki.hypr.land/configuring/
-- Planned work and disabled snippets live in TODO.md.

require("conf.animations")
require("conf.layouts")
require("conf.input")
require("conf.keymaps")
require("conf.lockscreen")
require("conf.notifications")
require("conf.rules")
require("conf.workspaces")
local programs = require("conf.programs")
local theme = require("conf.theme")

-- See https://wiki.hypr.land/configuring/core/monitors/
hl.monitor({
	output = "",
	mode = "preferred",
	position = "auto",
	scale = "auto",
})

-- See https://wiki.hypr.land/configuring/core/autostart/
hl.on("hyprland.start", function()
	hl.exec_cmd(programs.desktop_bar)
	hl.exec_cmd(programs.notification_center)
	hl.exec_cmd(programs.idle)
	hl.exec_cmd(programs.session)
	hl.exec_cmd(programs.wallpaper)
	hl.exec_cmd("~/.config/hypr/scripts/bing-wallpaper.sh start")
end)

-- See https://wiki.hypr.land/configuring/core/environment-variables/
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Refer to https://wiki.hypr.land/configuring/core/config-options/
hl.config({
	general = {
		-- gaps between windows
		gaps_in = 0,
		-- gaps between windows and monitor edges
		gaps_out = 0,

		border_size = 2,

		col = {
			active_border = theme.gradient("primary", "secondary", 0.6),
			inactive_border = theme.rgba("border_inactive", 0.67),
		},

		-- Set to true to enable resizing windows by clicking and dragging on borders and gaps
		resize_on_border = true,

		-- Please see https://wiki.hypr.land/configuring/extra/tearing/ before you turn this on
		allow_tearing = false,

		layout = "master",
	},

	decoration = {
		rounding = 4,
		rounding_power = 2,

		-- Change transparency of focused and unfocused windows
		active_opacity = 1.0,
		inactive_opacity = 1.0,

		shadow = {
			enabled = true,
			range = 4,
			render_power = 3,
			color = theme.rgba("background", 0.93),
		},

		blur = {
			enabled = true,
			size = 3,
			passes = 1,
			vibrancy = 0.1696,
		},
	},
})

-- Group tab: `color` darkened toward the background, glowing up from the bottom
-- edge. The groupbar ignores the angle: it stretches a vertical gradient over
-- each tab with the stops spaced evenly (max 10). The source orders them bottom
-- first, but the texture is drawn flipped, so on screen the list runs top-down.
-- From the bottom, the accent eases over `fade` stops into the tint, which is
-- `color` mixed `depth` (0..1) of the way to the background.
local function tabGradient(color, alpha, fade, depth)
	fade = fade or 6
	local tint = theme.mix(color, "background", depth or 0.5)
	local colors = { theme.rgba(color) }
	for i = 1, 9 do
		local t = 1 - (1 - math.min(i / fade, 1)) ^ 2 -- ease-out
		table.insert(colors, 1, theme.rgba(theme.mix(color, tint, t), alpha))
	end
	return { colors = colors }
end

local groupInactive = theme.rgba("border_inactive", 0.67)
local tabInactive = theme.rgba("surface", 0.8)

hl.config({
	group = {
		col = {
			border_active = theme.gradient("primary", "secondary", 0.6),
			border_inactive = groupInactive,
			-- locked groups keep their colors; the lock shows in waybar and the tab text
			border_locked_active = theme.gradient("primary", "secondary", 0.6),
			border_locked_inactive = groupInactive,
		},
		groupbar = {
			font_size = 12,
			height = 24,
			font_weight_active = "bold",
			-- filled tabs instead of the thin indicator strip
			gradients = true,
			indicator_height = 0,
			gradient_rounding = 4,
			rounding = 4,

			col = {
				active = tabGradient("primary", 0.93),
				inactive = tabInactive,
				locked_active = tabGradient("primary", 0.93),
				locked_inactive = tabInactive,
			},
			-- the groupbar can't draw icons, so unlocked tabs are marked by title color
			text_color = theme.rgba("warning"),
			text_color_inactive = theme.rgba("warning", 0.7),
			text_color_locked_active = theme.rgba("foreground"),
			text_color_locked_inactive = theme.rgba("muted"),
		},
	},
})

hl.config({
	misc = {
		force_default_wallpaper = -1, -- Set to 0 or 1 to disable the anime mascot wallpapers
		disable_hyprland_logo = true, -- If true disables the random hyprland logo / anime girl background. :(
	},
})

-- This is an example Hyprland Lua config file.
-- Refer to the wiki for more information.
-- https://wiki.hypr.land/configuring/
--
-- TODO:
-- - top bar
-- - replace hyprlauncher with something more like spotlight explore its features?
-- - reboot/logout menu
-- - lock screen (hyprlock?)
-- - fuzzy search keys
-- - which keys like experience
-- - notification center
-- - notification dismiss binding
-- - workspace indicator
-- - mission control like view
-- - better group theming/bars alternative
-- - coding orientation and cycle between layouts on workspaces and save them
-- - kde phone connect
-- - hidden workspace stuff to replicate minimizing stuff that i can pull up and view whenever and unminimize (special workspace(s))
-- - bing wallpapers (link in bar?)

require("conf.animations")
require("conf.layouts")
require("conf.input")
require("conf.keymaps")
require("conf.rules")
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
	hl.exec_cmd(programs.browser)
	-- hl.exec_cmd("nm-applet")
	-- hl.exec_cmd("waybar & hyprpaper & " .. programs.browser)
end)

-- See https://wiki.hypr.land/configuring/core/environment-variables/
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-----------------------
----- PERMISSIONS -----
-----------------------

-- See https://wiki.hypr.land/configuring/core/advanced-configuration/permissions/
-- Please note permission changes here require a Hyprland restart and are not applied on-the-fly
-- for security reasons

-- hl.config({
--   ecosystem = {
--     enforce_permissions = true,
--   },
-- })

-- hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
-- hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
-- hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")

-- Refer to https://wiki.hypr.land/configuring/core/config-options/
hl.config({
	general = {
		-- gaps between windows
		gaps_in = 0,
		-- gaps between windows and monitor edges
		gaps_out = 0,

		border_size = 2,

		col = {
			active_border = theme.gradient("primary", "secondary", 0.93),
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
			border_active = theme.gradient("primary", "secondary", 0.93),
			border_inactive = groupInactive,
			border_locked_active = theme.gradient("highlight", "error", 0.93),
			border_locked_inactive = groupInactive,
		},
		groupbar = {
			font_size = 12,
			height = 22,
			font_weight_active = "bold",
			-- filled tabs instead of the thin indicator strip
			gradients = true,
			indicator_height = 0,
			gradient_rounding = 4,
			rounding = 4,

			col = {
				active = tabGradient("primary", 0.93),
				inactive = tabInactive,
				locked_active = tabGradient("highlight", 0.93),
				locked_inactive = tabInactive,
			},
			text_color = theme.rgba("foreground"),
			text_color_inactive = theme.rgba("muted"),
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

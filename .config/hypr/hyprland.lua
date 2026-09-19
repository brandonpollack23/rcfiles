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
-- - make groups theming better/match easier to read etc
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
			active_border = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
			inactive_border = "rgba(595959aa)",
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
			color = 0xee1a1a1a,
		},

		blur = {
			enabled = true,
			size = 3,
			passes = 1,
			vibrancy = 0.1696,
		},
	},
})

hl.config({
	misc = {
		force_default_wallpaper = -1, -- Set to 0 or 1 to disable the anime mascot wallpapers
		disable_hyprland_logo = true, -- If true disables the random hyprland logo / anime girl background. :(
	},
})

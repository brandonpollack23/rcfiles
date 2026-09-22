-- Hyprspace workspace overview, a hyprpm plugin loaded (and installed, when
-- missing) at startup by `scripts/system.sh ensure-plugins` (hyprland.lua).
-- It comes from brandonpollack23/Hyprspace: the Lua-aware 0.56 fork in
-- KZDKM/Hyprspace#238 plus "id: name" labels under each workspace.
-- `scripts/system.sh plugins` installs or updates it.
--
-- The plugin registers its options and dispatchers when it loads, then reloads
-- the config, so everything here waits until it is actually loaded.

local theme = require("conf.theme")

local M = {}

local function loaded()
	for _, plugin in ipairs(hl.get_loaded_plugins()) do
		if plugin.name == "Hyprspace" then
			return true
		end
	end
	return false
end

function M.toggle()
	if not loaded() then
		hl.notification.create({
			text = "Hyprspace is not loaded (SUPER+SHIFT+R, then Install/update Hyprland plugins)",
			timeout = 5000,
		})
		return
	end
	hl.plugin.overview.toggle()
end

if loaded() then
	hl.config({
		plugin = {
			overview = {
				panelColor = theme.rgba("background", 0.8),
				panelBorderColor = theme.rgba("primary", 0.6),
				panelBorderWidth = 2,
				workspaceActiveBackground = theme.rgba("surface", 0.6),
				workspaceInactiveBackground = theme.rgba("background", 0.6),
				workspaceActiveBorder = theme.rgba("primary"),
				workspaceInactiveBorder = theme.rgba("border_inactive", 0.5),
				workspaceBorderSize = 2,
				-- the named workspaces only; no empty "+" slot, since the picker creates them
				showNewWorkspace = false,
				showEmptyWorkspace = true,
				exitOnSwitch = true,
				-- "id: name" under each workspace (the fork's patch); the font is
				-- misc:font_family and the active label is also bold
				showLabels = true,
				labelFontSize = 16,
				labelColor = theme.rgba("foreground", 0.65),
				labelActiveColor = theme.rgba("foreground"),
			},
		},
	})
end

return M

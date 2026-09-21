-- The bar's popups (~/.config/l1p0-menu) stay up until their module is clicked
-- again; neither l1p0-menus nor popups.py closes on its own. Close them the way
-- a menu closes: on a click anywhere else, or when another window takes focus.
-- Both only have a toggle, so that is what runs, and only for a popup that
-- `hl.get_layers` says is open.
local TOGGLE = {
	["audio-layer"] = "l1p0-menus --toggle audio",
	["brightness-layer"] = "l1p0-menus --toggle brightness",
	["calendar-layer"] = "l1p0-menus --toggle calendar",
	["battery-layer"] = "l1p0-menus --toggle battery",
	["network-layer"] = "l1p0-menus --toggle network",
	["pia-layer"] = "~/.config/l1p0-menu/popups.py pia",
	["weather-layer"] = "~/.config/l1p0-menu/popups.py weather",
	["capture-layer"] = "~/.config/hypr/scripts/capture.py",
}

-- The gap between the bar and a popup: with follow_mouse, crossing it focuses
-- the window underneath, which must not close the popup being reached for.
local SLACK = 12

local function under(layer, cursor, slack)
	return cursor.x >= layer.x - slack
		and cursor.x < layer.x + layer.w + slack
		and cursor.y >= layer.y - slack
		and cursor.y < layer.y + layer.h + slack
end

local function closeUnlessPointedAt()
	local open = {}
	for _, layer in ipairs(hl.get_layers()) do
		if TOGGLE[layer.namespace] and layer.mapped then
			table.insert(open, layer)
		end
	end
	local cursor = hl.get_cursor_pos()
	if #open == 0 or not cursor then
		return
	end

	-- The bar counts as the popup: a click on a module is already a toggle.
	for _, layer in ipairs(hl.get_layers({ namespace = "waybar" })) do
		if under(layer, cursor, 0) then
			return
		end
	end
	for _, layer in ipairs(open) do
		if under(layer, cursor, SLACK) then
			return
		end
	end
	for _, layer in ipairs(open) do
		hl.exec_cmd(TOGGLE[layer.namespace])
	end
end

hl.on("window.active", closeUnlessPointedAt)
-- Not through bind_helpers: nothing to list or run from the keybind search.
hl.bind("mouse:272", closeUnlessPointedAt, { non_consuming = true, description = "Close bar popups on click away" })

return { closeUnlessPointedAt = closeUnlessPointedAt }

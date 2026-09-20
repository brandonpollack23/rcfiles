-- Hidden workspaces: Hyprland special workspaces other than the default
-- scratchpad on SUPER+S.
--
-- They are addressed by name, never by id: their ids are large negatives and
-- must stay out of the id ordering in order.lua. The same rule picks them out
-- here and in the waybar buttons (~/.config/waybar/scripts/hidden-workspace.py):
-- every special workspace except DEFAULT, ascending by name.

local M = {}

-- The scratchpad has its own binds and waybar button, so the picker skips it.
M.DEFAULT = "Hidden"

-- Names of the existing hidden workspaces, ascending.
function M.list()
	local names = {}
	for _, workspace in ipairs(hl.get_workspaces()) do
		local name = workspace.special and workspace.name:match("^special:(.+)$")
		if name and name ~= M.DEFAULT then
			table.insert(names, name)
		end
	end
	table.sort(names)
	return names
end

-- Put away every hidden workspace on show, the default one included, and say
-- whether there was one. A monitor only ever holds one, and "" is how it is
-- cleared; toggle_special would hide it on the focused monitor but pull it over
-- from any other.
local function hideOpen()
	local hid = false
	for _, monitor in ipairs(hl.get_monitors()) do
		if monitor.active_special_workspace then
			monitor:set_special_workspace("")
			hid = true
		end
	end
	return hid
end

-- SUPER+S: put away whichever hidden workspace is up, whether it is the default
-- one or a named one, and raise the default one when none is.
function M.toggle()
	if not hideOpen() then
		hl.dispatch(hl.dsp.workspace.toggle_special(M.DEFAULT))
	end
end

-- How a hidden workspace reads in the picker. The ordinal is cosmetic.
function M.label(index, name)
	return "H" .. index .. ": " .. name
end

-- The name in a picker line, or nil when the line is not a hidden workspace.
-- Reading the name back rather than the ordinal keeps a stale list harmless.
function M.fromLabel(line)
	return line:match("^H%d+:%s*(.+)$")
end

-- A `special:<name>` selector is a single token, so names cannot hold spaces.
function M.clean(name)
	return (name:match("^%s*(.-)%s*$"):gsub("%s+", "-"))
end

return M

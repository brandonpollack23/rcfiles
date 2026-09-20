-- The workspace picker and the naming prompts, driven by
-- scripts/workspace-menu.sh: it renders the lines this module returns and hands
-- the answer back.

local ids = require("conf.workspaces.ids")
local order = require("conf.workspaces.order")

local M = {}

-- The picker line that creates a workspace instead of picking one.
local NEW = "+ New workspace"

-- `action` is "focus" (go there) or "move" (send the active window and follow).
local function goTo(action, id)
	if action == "move" then
		hl.dispatch(hl.dsp.window.move({ workspace = id }))
	else
		hl.dispatch(hl.dsp.focus({ workspace = id }))
	end
end

-- Newline-separated picker lines: the active workspace first (the launcher
-- highlights the first line), then the rest by id, with the create entry last.
function M.menu()
	local names, list, lines = ids.names(), {}, {}
	local active = hl.get_active_workspace()
	local activeId = active and active.id
	for id in pairs(names) do
		if id ~= activeId then
			table.insert(list, id)
		end
	end
	table.sort(list)
	if names[activeId] then
		table.insert(list, 1, activeId)
	end

	for _, id in ipairs(list) do
		table.insert(lines, ids.label(id, names[id]))
	end
	table.insert(lines, NEW)
	return table.concat(lines, "\n")
end

-- The suggested name for a new workspace: its id.
function M.newName()
	return tostring(ids.nextFree())
end

-- Act on a picked line. Returns true when done, or the suggested name when the
-- script should prompt for a new workspace (then call M.create).
function M.pick(action, line)
	if line == NEW then
		return M.newName()
	end
	local id = tonumber(line:match("^(%d+)"))
	if id then
		goTo(action, id)
	end
	return true
end

-- Create a workspace at `position` (an order.positions line), name it, go there.
function M.create(action, name, position)
	local id = order.placeAt(position or order.END)
	goTo(action, id)
	M.rename(id, name)
end

-- An empty name resets the label to the id.
function M.rename(id, name)
	name = name:match("^%s*(.-)%s*$")
	if name == "" then
		name = tostring(id)
	end
	hl.dispatch(hl.dsp.workspace.rename({ workspace = id, name = name }))
end

-- "<id>\n<name>" of the active normal workspace, for the rename prompt.
function M.active()
	local workspace = hl.get_active_workspace()
	return workspace.id .. "\n" .. workspace.name
end

return M

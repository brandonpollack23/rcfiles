-- The workspace picker and the naming prompts, driven by
-- scripts/workspace-menu.sh: it renders the lines this module returns and hands
-- the answer back.

local hidden = require("conf.workspaces.hidden")
local ids = require("conf.workspaces.ids")
local order = require("conf.workspaces.order")

local M = {}

-- The picker lines that create a workspace instead of picking one.
local NEW = "+ New workspace"
local NEW_HIDDEN = "+ New hidden workspace"

-- `action` is "focus" (go there) or "move" (send the active window and follow).
-- `selector` is a normal workspace id or a "special:<name>" hidden one.
local function goTo(action, selector)
	if action == "move" then
		hl.dispatch(hl.dsp.window.move({ workspace = selector }))
	else
		hl.dispatch(hl.dsp.focus({ workspace = selector }))
	end
end

-- Newline-separated picker lines: the active workspace first (the launcher
-- highlights the first line), then the rest by id, then the hidden workspaces,
-- with the create entries last.
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
	for index, name in ipairs(hidden.list()) do
		table.insert(lines, hidden.label(index, name))
	end
	table.insert(lines, NEW)
	table.insert(lines, NEW_HIDDEN)
	return table.concat(lines, "\n")
end

-- The suggested name for a new workspace: its id.
function M.newName()
	return tostring(ids.nextFree())
end

-- Act on a picked line. Tells scripts/workspace-menu.sh what to do next:
-- "done", "new\n<suggested name>" (prompt, then M.create) or "hidden" (prompt,
-- then M.createHidden).
function M.pick(action, line)
	if line == NEW then
		return "new\n" .. M.newName()
	end
	if line == NEW_HIDDEN then
		return "hidden"
	end
	local name = hidden.fromLabel(line)
	if name then
		goTo(action, "special:" .. name)
		return "done"
	end
	local id = tonumber(line:match("^(%d+)"))
	if id then
		goTo(action, id)
	end
	return "done"
end

-- Create a workspace at `position` (an order.positions line), name it, go there.
function M.create(action, name, position)
	local id = order.placeAt(position or order.END)
	goTo(action, id)
	M.rename(id, name)
end

-- How many hidden workspaces there are besides the default one. SUPER+SHIFT+S
-- only puts up a picker when this is more than zero; `repl` cannot carry an
-- empty string back (it reads as a failed request), so the count is the signal.
function M.hiddenCount()
	return #hidden.list()
end

-- SUPER+SHIFT+S sends the window to a hidden workspace: the default one first,
-- then the named ones.
function M.hiddenMenu()
	local lines = { hidden.DEFAULT }
	for index, name in ipairs(hidden.list()) do
		table.insert(lines, hidden.label(index, name))
	end
	table.insert(lines, NEW_HIDDEN)
	return table.concat(lines, "\n")
end

-- Send the active window to the hidden workspace on a hiddenMenu line; an empty
-- line means the default one. Returns "done", or "hidden" to prompt for a name.
-- A line this menu did not produce is ignored rather than taken for a name:
-- hyprlauncher prints a notice, not nothing, when it is dismissed.
function M.moveToHidden(line)
	if line == NEW_HIDDEN then
		return "hidden"
	end
	local name = hidden.fromLabel(line) or line
	if name == "" or name == hidden.DEFAULT then
		goTo("move", "special:" .. hidden.DEFAULT)
		return "done"
	end
	for _, existing in ipairs(hidden.list()) do
		if existing == name then
			goTo("move", "special:" .. name)
			break
		end
	end
	return "done"
end

-- Hidden workspaces have no placement: Hyprland creates one the moment it is
-- focused or a window lands on it, and the name is the whole address.
function M.createHidden(action, name)
	name = hidden.clean(name)
	if name == "" then
		return
	end
	goTo(action, "special:" .. name)
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

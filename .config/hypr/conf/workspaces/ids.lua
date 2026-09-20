-- Workspace ids and the labels built from them.
--
-- Workspaces are always addressed by id; the name is only a label. Names are set
-- through the prompts in picker.lua and are lost when Hyprland destroys the
-- workspace (empty and not visible).

local M = {}

-- Names of the existing normal workspaces, by id.
function M.names()
	local names = {}
	for _, workspace in ipairs(hl.get_workspaces()) do
		if not workspace.special then
			names[workspace.id] = workspace.name
		end
	end
	return names
end

-- Normal workspaces with a real id, ascending. Every ordering operation starts
-- from this list; only the direction they walk it differs.
function M.sorted()
	local workspaces = {}
	for _, workspace in ipairs(hl.get_workspaces()) do
		if not workspace.special and workspace.id >= 1 then
			table.insert(workspaces, workspace)
		end
	end
	table.sort(workspaces, function(a, b)
		return a.id < b.id
	end)
	return workspaces
end

-- How a workspace reads in the picker and the placement list.
function M.label(id, name)
	if name == "" or name == tostring(id) then
		return tostring(id)
	end
	return id .. ": " .. name
end

-- The lowest id not in use.
function M.nextFree()
	local names = M.names()
	local id = 1
	while names[id] do
		id = id + 1
	end
	return id
end

function M.change(workspace, id)
	hl.dispatch(hl.dsp.workspace.change_id({ workspace = workspace, id = id }))
end

return M

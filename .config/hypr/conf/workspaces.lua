-- Named workspaces: a picker to go to or move a window to a workspace, and
-- naming prompts, driven by scripts/workspace-menu.sh. Workspaces are always
-- addressed by id; the name is only a label. Names are set through the prompts
-- and are lost when Hyprland destroys the workspace (empty and not visible).
local M = {}

-- The picker line that creates a workspace instead of picking one.
local NEW = "+ New workspace"

-- Existing normal workspaces by id.
local function workspaceNames()
	local names = {}
	for _, workspace in ipairs(hl.get_workspaces()) do
		if not workspace.special then
			names[workspace.id] = workspace.name
		end
	end
	return names
end

local function label(id, name)
	if name == "" or name == tostring(id) then
		return tostring(id)
	end
	return id .. ": " .. name
end

local function nextFreeId()
	local names = workspaceNames()
	local id = 1
	while names[id] do
		id = id + 1
	end
	return id
end

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
	local names, ids, lines = workspaceNames(), {}, {}
	local active = hl.get_active_workspace()
	local activeId = active and active.id
	for id in pairs(names) do
		if id ~= activeId then
			table.insert(ids, id)
		end
	end
	table.sort(ids)
	if names[activeId] then
		table.insert(ids, 1, activeId)
	end

	for _, id in ipairs(ids) do
		table.insert(lines, label(id, names[id]))
	end
	table.insert(lines, NEW)
	return table.concat(lines, "\n")
end

-- The suggested name for a new workspace: its id.
function M.newName()
	return tostring(nextFreeId())
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

-- Create the lowest free workspace, name it, and go to it.
function M.create(action, name)
	local id = nextFreeId()
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

local function changeId(workspace, id)
	hl.dispatch(hl.dsp.workspace.change_id({ workspace = workspace, id = id }))
end

-- Swap the active workspace with the next existing one in id order (`delta` is
-- 1 or -1), so it moves one place even across gaps in the ids. Windows and the
-- name travel with the workspace.
function M.shift(delta)
	local workspace = hl.get_active_workspace()
	if not workspace or workspace.special or workspace.id < 1 then
		return
	end

	local ids, byId = {}, {}
	for _, existing in ipairs(hl.get_workspaces()) do
		if not existing.special and existing.id >= 1 then
			table.insert(ids, existing.id)
			byId[existing.id] = existing
		end
	end
	table.sort(ids)

	local from, to
	for i, id in ipairs(ids) do
		if id == workspace.id then
			from, to = id, ids[i + delta]
		end
	end
	if not to then
		return -- already first or last
	end
	local other = byId[to]

	-- change_id refuses an id in use, so park this workspace past the last one
	-- while the other takes its place.
	local parked = ids[#ids] + 1

	changeId(workspace, parked)
	if not hl.get_workspace(parked) then
		return -- change_id refused; leave both workspaces where they were
	end
	changeId(other, from)
	changeId(workspace, to)
end

-- Renumber normal workspaces to 1..N, keeping their order, so the ids match
-- what e+1/e-1 cycle through. Ascending order means each target id is free.
function M.compact()
	local workspaces = {}
	for _, workspace in ipairs(hl.get_workspaces()) do
		if not workspace.special and workspace.id >= 1 then
			table.insert(workspaces, workspace)
		end
	end
	table.sort(workspaces, function(a, b)
		return a.id < b.id
	end)
	for i, workspace in ipairs(workspaces) do
		if workspace.id ~= i then
			changeId(workspace, i)
		end
	end
end

-- Compact after a workspace comes or goes (e.g. Super+7 with three workspaces
-- lands on 4). Deferred so the event finishes before the ids change.
local function compactSoon()
	hl.timer(M.compact, { timeout = 1, type = "oneshot" })
end
hl.on("workspace.created", compactSoon)
hl.on("workspace.removed", compactSoon)
M.compact()

return M

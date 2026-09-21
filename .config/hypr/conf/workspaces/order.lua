-- Where a workspace sits in the sequence: the placement offered when one is
-- created, moving an existing one, and keeping the ids gap-free.

local ids = require("conf.workspaces.ids")

local M = {}

-- The placement vocabulary. These strings are both shown to the user and parsed
-- back out of the answer, so both halves live here.
local END, FIRST = "At the end", "First"

M.END = END

-- Set while a session restore is addressing workspaces by id (persist.lua):
-- renumbering under it would send the windows still to come to the wrong place.
local suspended = false

-- The placement lines for a new workspace, default first: the end, the start,
-- then after each existing workspace in id order.
function M.positions()
	local names = ids.names()
	local lines = { END, FIRST }
	for _, workspace in ipairs(ids.sorted()) do
		table.insert(lines, "After " .. ids.label(workspace.id, names[workspace.id]))
	end
	return table.concat(lines, "\n")
end

-- The id a new workspace gets for a placement line, bumping the workspaces after
-- it up by one to free it. Anything unrecognised (or empty) means the end.
function M.placeAt(position)
	local after = position == FIRST and 0 or tonumber(position:match("^After (%d+)"))
	if not after then
		return ids.nextFree()
	end

	local later = {}
	for _, workspace in ipairs(ids.sorted()) do
		if workspace.id > after then
			table.insert(later, workspace)
		end
	end
	-- Descending, so each target id is already free.
	for i = #later, 1, -1 do
		ids.change(later[i], later[i].id + 1)
	end
	return after + 1
end

-- Swap the active workspace with the next existing one in id order (`delta` is
-- 1 or -1), so it moves one place even across gaps in the ids. Windows and the
-- name travel with the workspace.
function M.shift(delta)
	local workspace = hl.get_active_workspace()
	if not workspace or workspace.special or workspace.id < 1 then
		return
	end

	local existing, byId = {}, {}
	for _, other in ipairs(ids.sorted()) do
		table.insert(existing, other.id)
		byId[other.id] = other
	end

	local from, to
	for i, id in ipairs(existing) do
		if id == workspace.id then
			from, to = id, existing[i + delta]
		end
	end
	if not to then
		return -- already first or last
	end
	local other = byId[to]

	-- change_id refuses an id in use, so park this workspace past the last one
	-- while the other takes its place.
	local parked = existing[#existing] + 1

	ids.change(workspace, parked)
	if not hl.get_workspace(parked) then
		return -- change_id refused; leave both workspaces where they were
	end
	ids.change(other, from)
	ids.change(workspace, to)
end

-- Renumber normal workspaces to 1..N, keeping their order, so the ids match what
-- e+1/e-1 cycle through. Ascending order means each target id is free.
function M.compact()
	if suspended then
		return
	end
	for i, workspace in ipairs(ids.sorted()) do
		if workspace.id ~= i then
			ids.change(workspace, i)
		end
	end
end

function M.suspend()
	suspended = true
end

function M.resume()
	suspended = false
	M.compact()
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

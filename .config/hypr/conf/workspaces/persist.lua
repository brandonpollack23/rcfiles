-- Carrying named workspaces through a hypr-persist session restore.
--
-- hypr-persist records each window's workspace by name and replays that name as
-- the workspace selector, which only works while name and id are the same
-- thing. Here the name is a label on an id, so a saved "Univalent" selects
-- nothing at login and every window lands on the active workspace.
--
-- So this module keeps its own name -> id file, and at login rewrites the saved
-- session into one that uses ids (M.prepare), holds compaction off while
-- scripts/session.sh replays it, puts each name back as its workspace appears,
-- and lets go when the script reports in (M.finish).

local ids = require("conf.workspaces.ids")
local layout = require("conf.workspaces.layout")
local order = require("conf.workspaces.order")

local M = {}

local dataHome = os.getenv("XDG_DATA_HOME") or (os.getenv("HOME") .. "/.local/share")
local SESSIONS = dataHome .. "/hypr-persist/sessions/"
local SAVED = SESSIONS .. "last.toml"
-- The id-addressed copy of SAVED; scripts/session.sh restores it by this name.
local REWRITTEN = SESSIONS .. "boot.toml"
-- "<id>\t<name>" per line.
local MAP = dataHome .. "/hypr-persist/workspace-ids"

-- If session.sh never reports in, stop holding compaction off after this long.
local GIVE_UP_MS = 120000

-- Names still to put back, by the id the rewritten session gives them.
local pending = {}
local restoring = false
local shuttingDown = false

local function readMap()
	local map = {}
	local file = io.open(MAP)
	if not file then
		return map
	end
	for line in file:lines() do
		local id, name = line:match("^(%d+)\t(.+)$")
		if id then
			map[name] = tonumber(id)
		end
	end
	file:close()
	return map
end

-- Note where every live workspace sits. Names no longer in use are kept: the
-- saved session may still mention a workspace that closed on the way out, and
-- only the names it mentions are ever looked up.
function M.record()
	if restoring or shuttingDown then
		return
	end
	local map = readMap()
	for _, workspace in ipairs(ids.sorted()) do
		map[workspace.name] = workspace.id
	end
	local lines = {}
	for name, id in pairs(map) do
		table.insert(lines, id .. "\t" .. name)
	end
	table.sort(lines)
	local file = io.open(MAP, "w")
	if not file then
		os.execute("mkdir -p '" .. dataHome .. "/hypr-persist'")
		file = io.open(MAP, "w")
	end
	if file then
		file:write(table.concat(lines, "\n"), "\n")
		file:close()
	end
end

local function applyPending()
	for _, workspace in ipairs(ids.sorted()) do
		local name = pending[workspace.id]
		if name then
			pending[workspace.id] = nil
			if workspace.name ~= name then
				hl.dispatch(hl.dsp.workspace.rename({ workspace = workspace.id, name = name }))
				layout.named(workspace.id)
			end
		end
	end
end

-- The workspace a `workspace = ...` session line names, or nil for other lines.
-- The toml writer quotes with ' when the name itself holds a " or a \.
local function workspaceOf(line)
	local quote, value = line:match("^workspace = ([\"'])(.*)%1$")
	if quote == '"' then
		value = value:gsub('\\(["\\])', "%1")
	end
	return value
end

-- Write the id-addressed copy of the saved session and start holding the
-- workspaces still for it. Returns whether there is anything to restore.
function M.prepare()
	local file = io.open(SAVED)
	if not file then
		return false
	end
	local lines = {}
	for line in file:lines() do
		table.insert(lines, line)
	end
	file:close()

	-- The normal workspaces the session uses, in their saved order, get 1..N: the
	-- same ids compaction would settle on. An unrecorded name sorts by its
	-- number if it is one, else last.
	local map, names, seen = readMap(), {}, {}
	for _, line in ipairs(lines) do
		local name = workspaceOf(line)
		if name and not name:match("^special") and not seen[name] then
			seen[name] = true
			table.insert(names, name)
		end
	end
	if #names == 0 then
		return false
	end
	local function rank(name)
		return map[name] or tonumber(name) or math.huge
	end
	table.sort(names, function(a, b)
		if rank(a) ~= rank(b) then
			return rank(a) < rank(b)
		end
		return a < b
	end)
	local idOf = {}
	for id, name in ipairs(names) do
		idOf[name] = id
		pending[id] = name
	end

	for i, line in ipairs(lines) do
		local name = workspaceOf(line)
		if name and idOf[name] then
			lines[i] = 'workspace = "' .. idOf[name] .. '"'
		end
	end
	local out = io.open(REWRITTEN, "w")
	if not out then
		pending = {}
		return false
	end
	out:write(table.concat(lines, "\n"), "\n")
	out:close()

	restoring = true
	order.suspend()
	applyPending() -- the workspace Hyprland starts on already exists
	hl.timer(M.finish, { timeout = GIVE_UP_MS, type = "oneshot" })
	return true
end

-- The restore is over: name what is there, close the gaps left by anything that
-- never opened, and go back to recording.
function M.finish()
	if not restoring then
		return
	end
	applyPending()
	pending = {}
	restoring = false
	order.resume()
	M.record()
end

-- Deferred past order.lua's own deferred compaction, so the ids recorded are
-- the settled ones.
function M.recordSoon()
	hl.timer(function()
		applyPending()
		M.record()
	end, { timeout = 50, type = "oneshot" })
end
M.record()
hl.on("workspace.created", M.recordSoon)
hl.on("workspace.removed", M.recordSoon)
-- Workspaces empty out as the session closes; that is not the order to keep.
hl.on("hyprland.shutdown", function()
	shuttingDown = true
end)

return M

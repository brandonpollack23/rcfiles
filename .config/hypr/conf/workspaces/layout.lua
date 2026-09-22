-- Which layout each workspace is in: focus or work/reference (conf/layouts.lua).
--
-- A layout is two settings Hyprland's master layout keeps per workspace: the
-- orientation and the master's share (mfact). Neither lasts. Both are gone once
-- the workspace empties and Hyprland destroys it, a first window always gets the
-- mfact from the config, and a layout message only reaches the focused
-- workspace. So the choice is kept here by workspace name, in a file so it
-- survives a restart, and put back wherever it may have been lost: the first
-- window on a workspace, a workspace getting its name, and a change to the
-- presets. A workspace that is not on screen then is marked stale and caught up
-- when it is shown.
--
-- Only those moments, never every time a workspace is shown: that would undo a
-- split dragged by hand.

local layouts = require("conf.layouts")

local M = {}

local dataHome = os.getenv("XDG_DATA_HOME") or (os.getenv("HOME") .. "/.local/share")
local DIR = dataHome .. "/hypr-persist"
-- "applied\t<signature>" once, then "<preset>\t<name>" per workspace that is not
-- in the default one.
local FILE = DIR .. "/workspace-layouts"

-- Preset names by workspace name, the default left out.
local byName = {}
-- Workspace names to catch up when they are next shown.
local stale = {}

-- What the non-default presets were when the file was written, so a reload can
-- tell whether they changed or only something else did (a theme change reloads
-- the config too).
local function signature()
	local parts = {}
	for key, preset in pairs(layouts.presets) do
		if key ~= layouts.DEFAULT then
			table.insert(parts, key .. "=" .. preset.orientation .. "," .. preset.mfact)
		end
	end
	table.sort(parts)
	return table.concat(parts, " ")
end

local function save()
	local lines = { "applied\t" .. signature() }
	for name, preset in pairs(byName) do
		table.insert(lines, preset .. "\t" .. name)
	end
	table.sort(lines, function(a, b)
		-- the signature stays first
		return a:match("^applied\t") ~= nil or (b:match("^applied\t") == nil and a < b)
	end)
	local file = io.open(FILE, "w")
	if not file then
		os.execute("mkdir -p '" .. DIR .. "'")
		file = io.open(FILE, "w")
	end
	if file then
		file:write(table.concat(lines, "\n"), "\n")
		file:close()
	end
end

-- Returns the signature the file was written with.
local function load()
	local file = io.open(FILE)
	if not file then
		return nil
	end
	local applied
	for line in file:lines() do
		local key, value = line:match("^([^\t]+)\t(.+)$")
		if key == "applied" then
			applied = value
		elseif key and layouts.presets[key] and key ~= layouts.DEFAULT then
			byName[value] = key
		end
	end
	file:close()
	return applied
end

-- The preset key a workspace is in.
function M.of(name)
	return byName[name] or layouts.DEFAULT
end

-- One per layout node: a group is a single node, laid out by its front tab.
local function tiledCount(workspace)
	local count = 0
	for _, window in ipairs(hl.get_workspace_windows(workspace)) do
		if window.mapped and window.visible and not window.floating then
			count = count + 1
		end
	end
	return count
end

-- Put the workspace's preset on it, or mark it stale when a layout message
-- cannot reach it now: it is not the one on screen, an open hidden workspace
-- would take the message instead, or it has no window for the message to act on.
-- Also held off while a window is fullscreen, because the orientation message
-- takes the focused window out of fullscreen.
local function apply(workspace)
	local active = hl.get_active_workspace()
	if
		not active
		or active.id ~= workspace.id
		or hl.get_active_special_workspace()
		or workspace.tiled_layout ~= "master"
		or workspace.has_fullscreen
		or tiledCount(workspace) == 0
	then
		stale[workspace.name] = true
		return
	end
	stale[workspace.name] = nil
	local preset = layouts.presets[M.of(workspace.name)]
	pcall(hl.dispatch, hl.dsp.layout("orientation" .. preset.orientation))
	pcall(hl.dispatch, hl.dsp.layout("mfact exact " .. preset.mfact))
end

local function catchUp()
	local workspace = hl.get_active_workspace()
	if workspace and stale[workspace.name] then
		apply(workspace)
	end
end

-- SUPER+ALT+O: flip the active workspace between focus and work/reference.
function M.toggle()
	local workspace = hl.get_active_workspace()
	if not workspace or workspace.special then
		return
	end
	local next = M.of(workspace.name) == "reference" and "focus" or "reference"
	byName[workspace.name] = next ~= layouts.DEFAULT and next or nil
	save()
	apply(workspace)
	hl.notification.create({ text = layouts.presets[next].label .. " layout", duration = 1500 })
end

-- A workspace was renamed from `old` (picker.lua). Its layout goes with it,
-- unless it was in the default one and the new name has one of its own.
function M.renamed(old, id)
	local workspace = hl.get_workspace(id)
	if not workspace or workspace.name == old then
		return
	end
	if byName[old] then
		byName[workspace.name], byName[old] = byName[old], nil
		save()
	end
	if byName[workspace.name] then
		apply(workspace)
	end
end

-- A workspace got back the name it had before a restart (persist.lua).
function M.named(id)
	local workspace = hl.get_workspace(id)
	if workspace and byName[workspace.name] then
		apply(workspace)
	end
end

-- A first window gets the config's mfact and, on a new workspace, the config's
-- orientation. Deferred so the window is in the layout and focused by then.
local function arrived(workspace)
	if not workspace or workspace.special or not byName[workspace.name] then
		return
	end
	local id = workspace.id
	hl.timer(function()
		local now = hl.get_workspace(id)
		if now and tiledCount(now) == 1 then
			apply(now)
		end
	end, { timeout = 20, type = "oneshot" })
end

hl.on("window.open", function(window)
	arrived(window.workspace)
end)
hl.on("window.move_to_workspace", function(_, workspace)
	arrived(workspace)
end)
hl.on("workspace.active", catchUp)
hl.on("workspace.special_active", catchUp)

-- Changed presets are a change to every workspace using them.
if load() ~= signature() then
	for name in pairs(byName) do
		stale[name] = true
	end
	save()
	hl.timer(catchUp, { timeout = 50, type = "oneshot" })
end

return M

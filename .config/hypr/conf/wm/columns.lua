-- Keeping the two slave columns still when a window leaves.
--
-- With `orientation = center` (conf/layouts.lua) Hyprland picks a slave's column
-- from its index in the node list: it walks the list and alternates, starting on
-- the side `center_master_fallback` names. Remove a node and every node after it
-- shifts up one and lands on the other side of the screen, which is the jump
-- this module undoes. The columns still have to stay balanced with the larger
-- one first, so losing a window from the larger column forces exactly one window
-- to cross -- but only one, instead of all of them.
--
-- The fix is to put the surviving nodes back in an order that hands each of them
-- the column it already had. `hl.dsp.window.swap` reorders two nodes without
-- touching focus, and `window.close` fires before Hyprland drops the node, so
-- the columns can be read off the screen while they are still the old ones.
--
-- Everything is read back from geometry rather than asked for: `SUPER+O`
-- (`orientationcycle`) sets an orientation on the workspace that no Lua getter
-- reports, so the only honest answer to "is this workspace centered" is the
-- three columns being there on screen.
--
-- Two assumptions worth knowing if this ever misbehaves. `swapWith` also warps
-- the cursor, which is a no-op only while `cursor:persistent_warps` is off --
-- turning that on would drag the pointer on every fixup, and with
-- `follow_mouse = 1` (conf/input.lua) that moves focus too. And `smart_resizing`
-- keeps a resized height with the slot rather than the window, so the one window
-- that has to cross inherits the height of the slot it lands in.

local windows = require("conf.wm.windows")

local M = {}

-- The pre-removal arrangement, per workspace, waiting for the pass that puts it
-- back. Keyed by id because the workspace object goes stale across the timer.
local pending = {}

-- Set from the moment a fixup is scheduled until it is over. The swaps it makes
-- are themselves layout changes, and a close arriving mid-flight would snapshot
-- the arrangement we are busy replacing.
local busy = false

-- What the last pass did, for `hyprctl repl`: this module has no other visible
-- output, and a rejected pass and a pass with nothing to do look identical.
M.last = {}

local function vec(v)
	if type(v) ~= "table" or type(v.x) ~= "number" or type(v.y) ~= "number" then
		return nil
	end
	return v.x, v.y
end

-- One window per layout node. A group is a single node, and `visible` is the
-- member Hyprland lays out -- true for the front tab even on a workspace that is
-- not on screen, which is what makes it the right test here.
local function nodesOf(workspace)
	local nodes = {}
	for _, window in ipairs(hl.get_workspace_windows(workspace)) do
		if window.mapped and window.visible and not window.floating then
			if window.fullscreen ~= 0 then
				return nil -- a fullscreen box is not the tiled layout
			end
			nodes[#nodes + 1] = window
		end
	end
	return nodes
end

-- The slaves, split by column and ordered top to bottom. The master column is
-- the widest one, and any extra masters share its x, so a node is a slave
-- exactly when it sits strictly to one side of that x.
local function columnsOf(nodes)
	local masterX, widest = nil, -1
	for _, node in ipairs(nodes) do
		local x = vec(node.at)
		local w = vec(node.size)
		if not x or not w then
			return nil
		end
		if w > widest then
			widest, masterX = w, x
		end
	end

	local left, right = {}, {}
	for _, node in ipairs(nodes) do
		local x, y = vec(node.at)
		if x < masterX then
			left[#left + 1] = { address = node.address, y = y }
		elseif x > masterX then
			right[#right + 1] = { address = node.address, y = y }
		end
	end

	local down = function(a, b)
		if a.y ~= b.y then
			return a.y < b.y
		end
		return a.address < b.address
	end
	table.sort(left, down)
	table.sort(right, down)
	return left, right
end

-- How the workspace is arranged right now, or nil when it is not a centered
-- master with slaves on both sides -- the only shape this module has anything to
-- say about. Both columns being occupied is what rules out the other
-- orientations, which stack every slave on one side of the master.
local function arrangement(workspace)
	if workspace.tiled_layout ~= "master" then
		return nil
	end

	local nodes = nodesOf(workspace)
	if not nodes then
		return nil
	end

	local left, right = columnsOf(nodes)
	if not left or #left == 0 or #right == 0 then
		return nil
	end

	-- Hyprland gives the larger column to the side it starts on, so counts that
	-- do not add up mean this is not a settled centered layout and the order
	-- below would be a guess.
	local rightFirst = hl.get_config("master.center_master_fallback") == "right"
	local total = #left + #right
	local larger = math.ceil(total / 2)
	local first, second = left, right
	if rightFirst then
		first, second = right, left
	end
	if #first ~= larger or #second ~= total - larger then
		return nil
	end

	-- It alternates from the first side, so interleaving the columns top to
	-- bottom gives back the node order it walked.
	local order, side = {}, {}
	for i = 1, #first do
		order[#order + 1] = first[i].address
		if second[i] then
			order[#order + 1] = second[i].address
		end
	end
	for _, node in ipairs(left) do
		side[node.address] = "left"
	end
	for _, node in ipairs(right) do
		side[node.address] = "right"
	end
	return { order = order, side = side, rightFirst = rightFirst }
end

-- The order that hands every survivor back its own column. Slot 1 is on the side
-- Hyprland starts from and they alternate from there; filling each slot with the
-- earliest survivor that belongs to it also keeps the columns in their
-- top-to-bottom order, so nothing shuffles vertically either. Only when a column
-- has run out of windows -- the crossing the balance forces -- does a slot take
-- whatever is left.
function M.desiredOrder(order, side, rightFirst)
	local first = rightFirst and "right" or "left"
	local other = rightFirst and "left" or "right"
	local taken, desired = {}, {}

	for slot = 1, #order do
		local wanted = slot % 2 == 1 and first or other
		local pick
		for index, address in ipairs(order) do
			if not taken[index] and side[address] == wanted then
				pick = index
				break
			end
		end
		if not pick then
			for index = 1, #order do
				if not taken[index] then
					pick = index
					break
				end
			end
		end
		taken[pick] = true
		desired[slot] = order[pick]
	end

	return desired
end

-- Walk the slots and bring the right window to each. Every step settles one slot
-- for good -- nothing later looks at it again -- so this ends after at most one
-- swap per slot, and makes no swap it does not need.
function M.swapsFor(current, desired)
	local now, at, swaps = {}, {}, {}
	for index, address in ipairs(current) do
		now[index], at[address] = address, index
	end

	for slot = 1, #desired do
		local wanted = desired[slot]
		if now[slot] ~= wanted then
			local other, displaced = at[wanted], now[slot]
			swaps[#swaps + 1] = { displaced, wanted }
			now[slot], now[other] = wanted, displaced
			at[wanted], at[displaced] = slot, other
		end
	end

	return swaps
end

-- A window the snapshot never saw -- one opened in the meantime, or a group that
-- changed heads -- means the columns we remembered no longer describe the
-- screen, and the honest move is to leave the layout alone.
local function allKnown(before, now)
	for _, address in ipairs(now.order) do
		if not before.side[address] then
			return false
		end
	end
	return true
end

local function pass(id)
	local before = pending[id]
	pending[id] = nil
	if not before then
		return "nothing pending"
	end

	local workspace = hl.get_workspace(id)
	if not workspace then
		return "workspace gone"
	end

	local now = arrangement(workspace)
	if not now then
		return "not a centered master"
	end
	if #now.order < 2 then
		return "too few slaves"
	end
	if not allKnown(before, now) then
		return "the stack moved on its own"
	end

	local swaps = M.swapsFor(now.order, M.desiredOrder(now.order, before.side, now.rightFirst))
	for _, pair in ipairs(swaps) do
		local one, other = windows.at(pair[1]), windows.at(pair[2])
		if not one or not other then
			return "a window went away mid-pass"
		end
		hl.dispatch(hl.dsp.window.swap({ window = one, target = other }))
	end

	return string.format("%d swap(s)", #swaps)
end

-- Deferred so the removal and the relayout it triggers are over before the
-- columns are read back, the same reason conf/workspaces/order.lua waits a tick.
local function passSoon(id)
	busy = true
	hl.timer(function()
		local ok, result = pcall(pass, id)
		busy = false
		M.last = { workspace = id, result = ok and result or ("error: " .. tostring(result)) }
	end, { timeout = 20, type = "oneshot" })
end

-- Closing a tab of a group leaves the node in place, so there is nothing to put
-- back; anything else takes a node with it.
local function takesANode(window)
	if window.floating or not window.visible then
		return false
	end
	local group = windows.groupOf(window)
	return not group or #group.members <= 1
end

-- Read the columns here rather than from anything observed earlier: this runs
-- before Hyprland drops the node, so they are still the old ones.
hl.on("window.close", function(window)
	local workspace = window.workspace
	if busy or not workspace or pending[workspace.id] or not takesANode(window) then
		return
	end
	local before = arrangement(workspace)
	if not before then
		return
	end
	pending[workspace.id] = before
	passSoon(workspace.id)
end)

-- Which workspace a window is on, because a move announces itself only once the
-- window already belongs to its new one and nothing reports the old.
local homes = {}

local function noteHome(window)
	if window and window.workspace then
		homes[window.address] = window.workspace.id
	end
end
hl.on("window.open", noteHome)
hl.on("window.active", noteHome)

-- A window moved away takes a node with it too. Its own node has not been handed
-- over yet when this fires, so the workspace it left still lays out the rest the
-- old way and the columns read true.
hl.on("window.move_to_workspace", function(window, workspace)
	local from = homes[window.address]
	noteHome(window)
	if busy or not from or (workspace and from == workspace.id) or pending[from] then
		return
	end
	local source = hl.get_workspace(from)
	local before = source and arrangement(source)
	if not before then
		return
	end
	pending[from] = before
	passSoon(from)
end)

return M

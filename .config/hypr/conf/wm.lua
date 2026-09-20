local M = {}

-- Addresses queued for closing while the confirmation dialog is open.
local pendingClose = nil

local function shellQuote(str)
	return "'" .. str:gsub("'", "'\\''") .. "'"
end

function M.closeOtherWindows()
	local active = hl.get_active_window()
	if not active then
		return
	end

	-- Prefer an open special workspace; otherwise use the normal workspace.
	local workspace = hl.get_active_special_workspace() or hl.get_active_workspace()

	if not workspace then
		return
	end

	-- The active window's group survives with it: the other tabs are part of
	-- what is being kept, not "other windows".
	local keep, grouped = { [active.address] = true }, 0
	if active.group then
		for _, member in pairs(active.group.members) do
			if not keep[member.address] then
				keep[member.address] = true
				grouped = grouped + 1
			end
		end
	end

	-- Snapshot now: the dialog steals focus, and windows opened while it is up
	-- should survive.
	local targets, count = {}, 0
	for _, window in pairs(hl.get_windows({ workspace = workspace })) do
		if not keep[window.address] then
			targets[window.address] = true
			count = count + 1
		end
	end

	if count == 0 then
		return
	end
	pendingClose = targets

	-- A blocking prompt would hang the compositor, so the dialog calls back in
	-- through hyprctl once answered. Enter confirms and Escape cancels natively.
	hl.exec_cmd(
		string.format(
			[=[if zenity --question --no-markup --title 'Close other windows?' --ok-label Close --cancel-label Cancel --text %s; then hyprctl eval 'require("conf.wm").confirmCloseOtherWindows()'; else hyprctl eval 'require("conf.wm").cancelCloseOtherWindows()'; fi]=],
			shellQuote(
				string.format(
					"Closes %d other window(s) on this workspace.\nKeeps: %s%s",
					count,
					active.title ~= "" and active.title or active.class,
					grouped > 0 and string.format(" (+%d in its group)", grouped) or ""
				)
			)
		),
		{ float = true }
	)
end

function M.confirmCloseOtherWindows()
	local targets = pendingClose
	pendingClose = nil
	if not targets then
		return
	end

	for _, window in pairs(hl.get_windows()) do
		if targets[window.address] then
			hl.dispatch(hl.dsp.window.close({ window = window }))
		end
	end
end

function M.cancelCloseOtherWindows()
	pendingClose = nil
end

-- Waybar's `custom/grouplock` module re-runs groupLockStatus on this signal.
local GROUP_LOCK_SIGNAL = 8

-- Waybar JSON for the lock indicator; empty text hides the module.
function M.groupLockStatus()
	local active = hl.get_active_window()
	if active and active.group and active.group.locked then
		return '{"text":"󰌾","tooltip":"Group locked: new windows open outside it","class":"locked"}'
	end
	return '{"text":""}'
end

function M.refreshGroupLock()
	hl.exec_cmd(string.format("pkill -RTMIN+%d -x waybar", GROUP_LOCK_SIGNAL))
end

-- Group history --------------------------------------------------------------
--
-- Hyprland has no undo of its own, and the Lua API fires no event for group
-- changes, so this covers exactly what goes through the actions below. A window
-- dragged onto a groupbar by mouse is invisible to it.
--
-- `HL.Group` has `add(window, index)` and `remove(window)`, which work on window
-- objects rather than on whatever happens to be focused, so a group can be put
-- back the way it was, tab order included.

local MAX_HISTORY = 30
local undoStack, redoStack = {}, {}

local function windowAt(address)
	for _, window in pairs(hl.get_windows()) do
		if window.address == address then
			return window
		end
	end
end

-- `window.group` sometimes reports a group the window is not actually in, so
-- trust it only when the members include the window itself.
local function groupOf(window)
	if not window or not window.group then
		return nil
	end
	for index, member in ipairs(window.group.members) do
		if member.address == window.address then
			return window.group, index
		end
	end
	return nil
end

-- Addresses of every member but `window`, in tab order, for putting a group back
-- together later. Window objects would go stale; addresses can be re-resolved.
local function memberAddresses(group)
	local addresses = {}
	for index, member in ipairs(group.members) do
		addresses[index] = member.address
	end
	return addresses
end

local function notify(text)
	hl.notification.create({ text = text, duration = 1500 })
end

-- An action records the pair of closures that replay it either way. Each returns
-- false when the windows it needs are gone, which drops the entry.
local function record(label, undo, redo)
	table.insert(undoStack, { label = label, undo = undo, redo = redo })
	if #undoStack > MAX_HISTORY then
		table.remove(undoStack, 1)
	end
	redoStack = {}
end

-- Primitives the history replays with.

local function detach(address)
	local window = windowAt(address)
	local group = groupOf(window)
	if not group then
		return false
	end
	group:remove(window)
	M.refreshGroupLock()
	return true
end

-- Puts `address` back into whatever group `anchor` is in, at `index`.
local function attach(address, anchor, index)
	local window, host = windowAt(address), windowAt(anchor)
	local group = groupOf(host)
	if not window or not group then
		return false
	end
	group:add(window, index)
	M.refreshGroupLock()
	return true
end

-- Rebuilds a dissolved group: the first surviving member becomes a group of one
-- and the rest join it in their old order.
local function rebuild(addresses)
	local first, rest = nil, {}
	for _, address in ipairs(addresses) do
		local window = windowAt(address)
		if window then
			if first then
				table.insert(rest, window)
			else
				first = window
			end
		end
	end
	if not first or #rest == 0 then
		return false
	end

	-- Creating a group is the one thing with no window-object API; the
	-- dispatcher acts on the focused window, so focus has to move once.
	hl.dispatch(hl.dsp.focus({ window = first }))
	hl.dispatch(hl.dsp.group.toggle())
	local group = groupOf(windowAt(first.address))
	if not group then
		return false
	end
	for _, window in ipairs(rest) do
		group:add(window)
	end
	M.refreshGroupLock()
	return true
end

local function replay(from, to, key, verb)
	while #from > 0 do
		local action = table.remove(from)
		if action[key]() then
			table.insert(to, action)
			notify(verb .. ": " .. action.label)
			return
		end
		-- Its windows are gone; drop it and try the one before.
	end
	notify("Nothing to " .. verb:lower())
end

function M.undo()
	replay(undoStack, redoStack, "undo", "Undo")
end

function M.redo()
	replay(redoStack, undoStack, "redo", "Redo")
end

-- Group actions --------------------------------------------------------------

-- Toggling a lone window makes a group of one; toggling a grouped window
-- dissolves the whole group, which is the destructive direction worth recording.
function M.toggleGroup()
	local active = hl.get_active_window()
	if not active then
		return
	end
	local address = active.address
	local group = groupOf(active)
	local members = group and memberAddresses(group) or nil

	hl.dispatch(hl.dsp.group.toggle())
	M.refreshGroupLock()

	if members and #members > 1 then
		record("dissolve group of " .. #members, function()
			return rebuild(members)
		end, function()
			local window = windowAt(address)
			if not groupOf(window) then
				return false
			end
			hl.dispatch(hl.dsp.focus({ window = window }))
			hl.dispatch(hl.dsp.group.toggle())
			M.refreshGroupLock()
			return true
		end)
	end
end

function M.toggleGroupLock()
	hl.dispatch(hl.dsp.group.lock_active())
	M.refreshGroupLock()
end

-- Hyprland picks the group to join by direction, so callers (the SUPER + ALT + G
-- submap) supply one. `into_or_create_group` also groups with a lone window,
-- which plain `into_group` refuses.
function M.groupWith(direction)
	local active = hl.get_active_window()
	if not active then
		return
	end
	local address = active.address

	hl.dispatch(hl.dsp.window.move({ into_or_create_group = direction }))
	M.refreshGroupLock()

	-- Nothing to record if there was no group that way.
	local group, index = groupOf(windowAt(address))
	if not group then
		return
	end
	local anchor
	for _, member in ipairs(group.members) do
		if member.address ~= address then
			anchor = member.address
			break
		end
	end
	if not anchor then
		return
	end

	record("group " .. direction, function()
		return detach(address)
	end, function()
		return attach(address, anchor, index)
	end)
end

-- Address queued for ungrouping while the confirmation dialog is open.
local pendingUngroup = nil

-- Pops the active window out on its own; the rest of the group stays together.
-- Asks first, the same way closing other windows does.
function M.ungroup()
	local active = hl.get_active_window()
	local group = groupOf(active)
	if not group then
		return
	end

	local others = 0
	for _, member in ipairs(group.members) do
		if member.address ~= active.address then
			others = others + 1
		end
	end
	-- Nothing to ask about when it has the group to itself.
	if others == 0 then
		return
	end

	-- Snapshot now: the dialog takes focus, and the answer has to name its
	-- target rather than whatever is focused once the dialog closes.
	pendingUngroup = active.address

	hl.exec_cmd(
		string.format(
			[=[if zenity --question --no-markup --title 'Move window out of its group?' --ok-label Ungroup --cancel-label Cancel --text %s; then hyprctl eval 'require("conf.wm").confirmUngroup()'; else hyprctl eval 'require("conf.wm").cancelUngroup()'; fi]=],
			shellQuote(
				string.format(
					"Moves out on its own: %s\nThe other %d window(s) stay grouped.",
					active.title ~= "" and active.title or active.class,
					others
				)
			)
		),
		{ float = true }
	)
end

function M.confirmUngroup()
	local address = pendingUngroup
	pendingUngroup = nil

	local window = address and windowAt(address)
	local group, index = groupOf(window)
	if not group then
		return
	end

	local anchor
	for _, member in ipairs(group.members) do
		if member.address ~= address then
			anchor = member.address
			break
		end
	end

	group:remove(window)
	M.refreshGroupLock()
	-- The dialog took focus; hand it back to the window that was ungrouped.
	hl.dispatch(hl.dsp.focus({ window = windowAt(address) }))

	if anchor then
		record("ungroup", function()
			return attach(address, anchor, index)
		end, function()
			return detach(address)
		end)
	end
end

function M.cancelUngroup()
	pendingUngroup = nil
end

-- Reorder the active window among its group's tabs.
function M.moveInGroup(forward)
	local active = hl.get_active_window()
	local group, index = groupOf(active)
	if not group then
		return
	end
	local address = active.address
	local anchor
	for _, member in ipairs(group.members) do
		if member.address ~= address then
			anchor = member.address
			break
		end
	end

	hl.dispatch(hl.dsp.group.move_window({ forward = forward }))

	local _, moved = groupOf(windowAt(address))
	if not anchor or moved == index then
		return
	end

	-- Replayed as "put it back at the index it held", which survives other tabs
	-- moving in between better than reversing the direction would.
	local function reindex(target)
		return function()
			return detach(address) and attach(address, anchor, target)
		end
	end
	record(forward and "move later in group" or "move earlier in group", reindex(index), reindex(moved))
end

hl.on("window.active", M.refreshGroupLock)

return M

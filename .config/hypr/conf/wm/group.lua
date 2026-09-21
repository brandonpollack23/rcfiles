-- Window groups: every action that changes one, and telling waybar it happened.
--
-- `HL.Group` has `add(window, index)` and `remove(window)`, which act on window
-- objects rather than on whatever happens to be focused. The dispatchers do not:
-- they ignore a `window` selector and always act on the focused window. So the
-- actions below use the dispatchers to make a change and the group methods to
-- put one back, which is what lets undo restore tab order exactly.

local dialog = require("conf.wm.dialog")
local history = require("conf.wm.history")
local taskbar = require("conf.wm.taskbar")
local windows = require("conf.wm.windows")

local M = {}

-- Telling waybar ---------------------------------------------------------------

-- Grouping, ungrouping, reordering tabs and locking all change what waybar's
-- taskbar should be drawing, and none of them has a Hyprland event behind it.
-- Every action below calls this once it has made its change.
M.refreshBar = taskbar.refresh

-- Focus moving between groups changes which entries are filled, and that one
-- does have an event.
hl.on("window.active", M.refreshBar)

-- Primitives the history replays with -----------------------------------------

local function detach(address)
	local window = windows.at(address)
	local group = windows.groupOf(window)
	if not group then
		return false
	end
	group:remove(window)
	M.refreshBar()
	return true
end

-- Puts `address` back into whatever group `anchor` is in, at `index`.
local function attach(address, anchor, index)
	local window, host = windows.at(address), windows.at(anchor)
	local group = windows.groupOf(host)
	if not window or not group then
		return false
	end
	group:add(window, index)
	M.refreshBar()
	return true
end

-- Rebuilds a dissolved group: the first surviving member becomes a group of one
-- and the rest join it in their old order.
local function rebuild(addresses)
	local first, rest = nil, {}
	for _, address in ipairs(addresses) do
		local window = windows.at(address)
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
	local group = windows.groupOf(windows.at(first.address))
	if not group then
		return false
	end
	for _, window in ipairs(rest) do
		group:add(window)
	end
	M.refreshBar()
	return true
end

-- Actions ---------------------------------------------------------------------

-- Toggling a lone window makes a group of one; toggling a grouped window
-- dissolves the whole group, which is the destructive direction worth recording.
function M.toggle()
	local active = hl.get_active_window()
	if not active then
		return
	end
	local address = active.address
	local group = windows.groupOf(active)
	local members = group and windows.memberAddresses(group) or nil

	hl.dispatch(hl.dsp.group.toggle())
	M.refreshBar()

	if members and #members > 1 then
		history.record("dissolve group of " .. #members, function()
			return rebuild(members)
		end, function()
			local window = windows.at(address)
			if not windows.groupOf(window) then
				return false
			end
			hl.dispatch(hl.dsp.focus({ window = window }))
			hl.dispatch(hl.dsp.group.toggle())
			M.refreshBar()
			return true
		end)
	end
end

function M.toggleLock()
	hl.dispatch(hl.dsp.group.lock_active())
	M.refreshBar()
end

-- Hyprland picks the group to join by direction, so callers (the SUPER + ALT + G
-- submap) supply one. `into_or_create_group` also groups with a lone window,
-- which plain `into_group` refuses. A lock only stops new windows from landing
-- in a group, so an explicit join ignores it; the option is flipped just for
-- this dispatch so the other group moves keep honouring locks.
function M.joinToward(direction)
	local active = hl.get_active_window()
	if not active then
		return
	end
	local address = active.address

	local ignoredLock = hl.get_config("binds.ignore_group_lock")
	hl.config({ binds = { ignore_group_lock = true } })
	hl.dispatch(hl.dsp.window.move({ into_or_create_group = direction }))
	hl.config({ binds = { ignore_group_lock = ignoredLock } })
	M.refreshBar()

	-- Nothing to record if there was no group that way.
	local group, index = windows.groupOf(windows.at(address))
	if not group then
		return
	end
	local anchor = windows.anchorFor(group, address)
	if not anchor then
		return
	end

	history.record("group " .. direction, function()
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
	local group = windows.groupOf(active)
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

	dialog.ask({
		title = "Move window out of its group?",
		ok = "Ungroup",
		text = string.format(
			"Moves out on its own: %s\nThe other %d window(s) stay grouped.",
			active.title ~= "" and active.title or active.class,
			others
		),
		confirm = 'require("conf.wm").confirmUngroup()',
		cancel = 'require("conf.wm").cancelUngroup()',
	})
end

function M.confirmUngroup()
	local address = pendingUngroup
	pendingUngroup = nil

	-- Re-read the group now rather than trusting what was captured before the
	-- dialog: it has been up for as long as the user took to answer.
	local window = address and windows.at(address)
	local group, index = windows.groupOf(window)
	if not group then
		return
	end
	local anchor = windows.anchorFor(group, address)

	group:remove(window)
	M.refreshBar()
	-- The dialog took focus; hand it back to the window that was ungrouped.
	hl.dispatch(hl.dsp.focus({ window = windows.at(address) }))

	if anchor then
		history.record("ungroup", function()
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
	local group, index = windows.groupOf(active)
	if not group then
		return
	end
	local address = active.address
	local anchor = windows.anchorFor(group, address)

	hl.dispatch(hl.dsp.group.move_window({ forward = forward }))

	local _, moved = windows.groupOf(windows.at(address))
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
	history.record(forward and "move later in group" or "move earlier in group", reindex(index), reindex(moved))
end

return M

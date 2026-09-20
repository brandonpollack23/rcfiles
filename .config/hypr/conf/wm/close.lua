-- Closing every window on the workspace but the focused one.

local dialog = require("conf.wm.dialog")

local M = {}

-- Addresses queued for closing while the confirmation dialog is open.
local pending = nil

function M.closeOthers()
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
	pending = targets

	dialog.ask({
		title = "Close other windows?",
		ok = "Close",
		text = string.format(
			"Closes %d other window(s) on this workspace.\nKeeps: %s%s",
			count,
			active.title ~= "" and active.title or active.class,
			grouped > 0 and string.format(" (+%d in its group)", grouped) or ""
		),
		confirm = 'require("conf.wm").confirmCloseOtherWindows()',
		cancel = 'require("conf.wm").cancelCloseOtherWindows()',
	})
end

function M.confirm()
	local targets = pending
	pending = nil
	if not targets then
		return
	end

	for _, window in pairs(hl.get_windows()) do
		if targets[window.address] then
			hl.dispatch(hl.dsp.window.close({ window = window }))
		end
	end
end

function M.cancel()
	pending = nil
end

return M

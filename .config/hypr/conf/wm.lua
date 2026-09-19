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

function M.toggleGroup()
	hl.dispatch(hl.dsp.group.toggle())
	M.refreshGroupLock()
end

function M.toggleGroupLock()
	hl.dispatch(hl.dsp.group.lock_active())
	M.refreshGroupLock()
end

hl.on("window.active", M.refreshGroupLock)

return M

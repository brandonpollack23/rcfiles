local M = {}

-- Addresses queued for closing while the confirmation dialog is open.
local pendingClose = nil

local function shellQuote(str)
	return "'" .. str:gsub("'", "'\\''") .. "'"
end

-- TODO make group preserved
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

	-- Snapshot now: the dialog steals focus, and windows opened while it is up
	-- should survive.
	local targets, count = {}, 0
	for _, window in pairs(hl.get_windows({ workspace = workspace })) do
		if window.address ~= active.address then
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
					"Closes %d other window(s) on this workspace.\nKeeps: %s",
					count,
					active.title ~= "" and active.title or active.class
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

return M

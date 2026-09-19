local M = {}

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

	local windows = hl.get_windows({ workspace = workspace })

	for _, window in pairs(windows) do
		if window.address ~= active.address then
			hl.dispatch(hl.dsp.window.close({ window = window }))
		end
	end
end

return M

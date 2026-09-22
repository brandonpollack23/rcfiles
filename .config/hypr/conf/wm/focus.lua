-- Putting keyboard focus back after the lock screen.
--
-- Hyprland drops keyboard focus the moment a session lock starts, and on
-- unlock only calls `CInputManager::refocus()` -- a synthetic mouse move, so
-- what ends up focused is whatever the pointer happens to be sitting on. Over
-- waybar, over a gap, or over nothing at all, and the session comes back with
-- no focused window: keys go nowhere and the taskbar draws no active entry.
--
-- Neither `.socket2.sock` nor `hl.on` has an unlock event, but hypridle does:
-- its `on_unlock_cmd` (hypridle.conf) reaches this through conf/lock.lua on
-- Hyprland's lock-notify `unlocked`. Hyprland sends that just before running
-- its own refocus in the same call, so by the time the command gets back here
-- the refocus is done.

local taskbar = require("conf.wm.taskbar")

local M = {}

-- The window Hyprland should have gone back to: the most recently focused one
-- on the workspace that is up. focus_history_id counts outward from the
-- focused window, so 0 is the one that had focus when the lock took it away.
local function lastFocused()
	local workspace = hl.get_active_special_workspace() or hl.get_active_workspace()
	if not workspace then
		return nil
	end

	local best = nil
	for _, window in pairs(hl.get_windows({ workspace = workspace })) do
		if window.mapped and (not best or window.focus_history_id < best.focus_history_id) then
			best = window
		end
	end
	return best
end

function M.restore()
	if not hl.get_active_window() then
		local window = lastFocused()
		if window then
			hl.dispatch(hl.dsp.focus({ window = window }))
		end
	end

	-- Unconditionally, for the case where Hyprland did refocus on its own: the
	-- taskbar drew itself empty when the lock took focus, and focus landing
	-- back on the window it was already on fires no event to draw it again.
	taskbar.refresh()
end

return M

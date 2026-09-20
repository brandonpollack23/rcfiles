-- What waybar's taskbar needs that Hyprland's IPC does not report.
--
-- `hyprctl clients` describes every window well enough to lay the taskbar out
-- -- position, group membership, tab order -- with two gaps: whether a group is
-- locked, and any way to act on a window that is not the focused one. Both are
-- only reachable from Lua, so the taskbar scripts come back in through here.

local windows = require("conf.wm.windows")

local M = {}

-- The taskbar scripts follow Hyprland's event socket and live for as long as
-- waybar does, so the signal waybar handles for its own modules never reaches
-- them. They listen for this one themselves. The pattern matches only the
-- rendering processes -- `windows.py <slot>` -- and not the short-lived
-- `windows.py focus <slot>` a click spawns, which a realtime signal would kill.
local SIGNAL = 8
local RENDERERS = "scripts/windows[.]py [0-9]"

-- Group lock and group membership have no Hyprland event behind them, so every
-- action that changes one calls this.
function M.refresh()
	hl.exec_cmd(string.format("pkill -RTMIN+%d -f %q", SIGNAL, RENDERERS))
end

-- Every window whose group is locked, space separated. A lock belongs to the
-- group rather than to a window, which is what lets the taskbar mark a locked
-- group that is not the focused one.
function M.lockedAddresses()
	local addresses = {}
	for _, window in pairs(hl.get_windows()) do
		-- groupOf, not window.group: see the note in windows.lua.
		local group = windows.groupOf(window)
		if group and group.locked then
			addresses[#addresses + 1] = window.address
		end
	end
	return table.concat(addresses, " ")
end

-- Clicking a taskbar entry lands here. The entry knows an address because the
-- window under a given slot changes as windows come and go, and the focus
-- dispatcher needs the window itself.
function M.focusAddress(address)
	local window = windows.at(address)
	if window then
		hl.dispatch(hl.dsp.focus({ window = window }))
	end
end

return M

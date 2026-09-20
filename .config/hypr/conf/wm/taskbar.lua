-- What waybar's taskbar needs that Hyprland's IPC does not report.
--
-- `hyprctl clients` describes every window well enough to lay the taskbar out
-- -- position, group membership, tab order -- with two gaps: whether a group is
-- locked, and any way to act on a window that is not the focused one. Both are
-- only reachable from Lua, so the taskbar scripts come back in through here.

local windows = require("conf.wm.windows")

local M = {}

-- The one daemon behind every taskbar button reads commands from a FIFO; this
-- script is the only thing that writes to it, and does nothing when the daemon
-- is not running. See ~/.config/waybar/brpol-waybard/README.md.
local CTL = "~/.config/waybar/brpol-waybard/scripts/ctl.sh"

-- Group lock and group membership have no Hyprland event behind them, so every
-- action that changes one calls this.
function M.refresh()
	hl.exec_cmd(CTL .. " refresh")
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

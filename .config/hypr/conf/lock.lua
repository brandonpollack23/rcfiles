-- What happens when the session locks and unlocks, and who is asking.
--
-- Neither `.socket2.sock` nor `hl.on` has a lock event, but hypridle does:
-- its `on_lock_cmd` and `on_unlock_cmd` (hypridle.conf) call `locked()` and
-- `unlocked()` here on Hyprland's lock-notify, however the lock was started.
--
-- While locked the device sounds stay quiet, and nothing else: music keeps
-- playing. That lives in brpol-waybard (hotplug.py), told through its control
-- FIFO. Unlocking also puts keyboard focus back (conf/wm/focus.lua).
--
-- `quiet()` is for things that should not be announced while locked, or just
-- after: hypridle turns the screens off a minute into a lock, and the primary
-- monitor drops off and comes back with them, which conf/hotplug.lua would
-- otherwise greet with a sound.

local M = {}

local CTL = "~/.config/waybar/brpol-waybard/scripts/ctl.sh "
-- How long after an unlock still counts as the lock's own noise.
local SETTLE_MS = 10000

local locked = false
local settling = nil

function M.locked()
	locked = true
	if settling then
		settling:set_enabled(false)
		settling = nil
	end
	hl.exec_cmd(CTL .. "locked")
end

function M.unlocked()
	locked = false
	hl.exec_cmd(CTL .. "unlocked")
	if settling then
		settling:set_enabled(false)
	end
	settling = hl.timer(function()
		settling = nil
	end, { timeout = SETTLE_MS, type = "oneshot" })
	require("conf.wm").restoreFocus()
end

function M.quiet()
	return locked or settling ~= nil
end

return M

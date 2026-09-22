-- Sound and notification when a monitor is plugged in or unplugged, through the
-- daemon that listens to udev for USB devices and the charger
-- (hotplug.py in ~/.config/waybar/brpol-waybard). Not while the session is
-- locked or just unlocked: the screens going off and on behind the lock are
-- not a monitor being plugged in (conf/lock.lua).
local lock = require("conf.lock")
local shellQuote = require("conf.wm.dialog").shellQuote

local CTL = "~/.config/waybar/brpol-waybard/scripts/ctl.sh announce "

-- The monitors already there at startup are announced as added too.
local ready = false
hl.timer(function()
	ready = true
end, { timeout = 5000, type = "oneshot" })

local function announce(action)
	return function(monitor)
		if not ready or lock.quiet() then
			return
		end
		local name = monitor.description ~= "" and monitor.description or monitor.name
		hl.exec_cmd(CTL .. action .. " monitor " .. shellQuote(name))
	end
end

hl.on("monitor.added", announce("added"))
hl.on("monitor.removed", announce("removed"))

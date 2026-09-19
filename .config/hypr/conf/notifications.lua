-- Vim keys for the swaync control center (SUPER+N). swaync's own shortcuts are
-- hardcoded (arrows, Delete, Shift+C, ...), so while the panel is open a submap
-- remaps keys onto them. Keys go out through ydotool, which Hyprland reads like
-- a real keyboard; the arrow keys are unbound in the submap, so they reach the
-- panel. The hint line at the top of the panel lives in ~/.config/swaync/config.json.
local helpers = require("conf.bind_helpers")

local bindExec = helpers.bindExec

local SUBMAP = "notifications"
local NAMESPACE = "swaync-control-center"

-- Linux input keycodes, see /usr/include/linux/input-event-codes.h
local KEY = { enter = 28, home = 102, up = 103, ["end"] = 107, down = 108, delete = 111 }

local function sendKey(code)
	return "ydotool key " .. code .. ":1 " .. code .. ":0"
end

hl.define_submap(SUBMAP, function()
	local function key(keys, code, description, opts)
		opts = opts or {}
		opts.description = "Notifications: " .. description
		bindExec(keys, sendKey(code), opts)
	end

	key("j", KEY.down, "next", { repeating = true })
	key("k", KEY.up, "previous", { repeating = true })
	key("g", KEY["end"], "oldest")
	key("SHIFT + g", KEY.home, "newest")
	key("l", KEY.enter, "open")
	key("d", KEY.delete, "dismiss selected")
	key("x", KEY.delete, "dismiss selected")
	bindExec("a", "swaync-client -C -sw", { description = "Notifications: dismiss all" })
	bindExec("m", "swaync-client -d -sw", { description = "Notifications: toggle do not disturb" })
	bindExec("h", "swaync-client -cp -sw", { description = "Notifications: close panel" })
	bindExec("q", "swaync-client -cp -sw", { description = "Notifications: close panel" })
	bindExec("SUPER + N", "swaync-client -cp -sw", { description = "Notifications: close panel" })
end)

-- Follow the panel however it opens or closes (SUPER+N, Escape, waybar click).
hl.on("layer.opened", function(layer)
	if layer.namespace == NAMESPACE then
		hl.dispatch(hl.dsp.submap(SUBMAP))
	end
end)
hl.on("layer.closed", function(layer)
	if layer.namespace == NAMESPACE and hl.get_current_submap() == SUBMAP then
		hl.dispatch(hl.dsp.submap("reset"))
	end
end)

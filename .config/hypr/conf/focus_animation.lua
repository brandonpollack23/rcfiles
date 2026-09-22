-- hyprfocus focus animation: the window that gets focus hops up a few pixels
-- and bounces back down. hyprfocus is from hyprwm/hyprland-plugins, a hyprpm
-- plugin loaded (and installed, when missing) at startup by
-- `scripts/system.sh ensure-plugins` (hyprland.lua).
-- `scripts/system.sh plugins` installs or updates it.
--
-- Its "slide" mode moves the window up by slide_height on the hyprfocusIn
-- animation, then back to rest on hyprfocusOut; the bounce is all in the
-- curves: a quick rise, then a fall whose bezier overshoots, so the window
-- lands a little below rest and settles back up.
--
-- The plugin registers its options and animation leaves when it loads, then
-- reloads the config, so everything here waits until it is actually loaded.

-- the second control point's y above 1 is the overshoot: about 1.5px past rest
-- for an 8px hop
hl.curve("focusBounce", { type = "bezier", points = { { 0.3, 1.8 }, { 0.55, 1 } } })

for _, plugin in ipairs(hl.get_loaded_plugins()) do
	if plugin.name == "hyprfocus" then
		hl.config({
			plugin = {
				hyprfocus = {
					enable = true,
					animate_floating = true,
					keyboard_focus_animation = "slide",
					-- follow_mouse (conf/input.lua) and clicks too
					mouse_focus_animation = "slide",
					-- logical pixels
					slide_height = 8,
				},
			},
		})
		hl.animation({ leaf = "hyprfocusIn", enabled = true, speed = 1.2, bezier = "easeOutQuint" })
		hl.animation({ leaf = "hyprfocusOut", enabled = true, speed = 3.5, bezier = "focusBounce" })
	end
end

-- See https://wiki.hypr.land/configuring/core/rules/

-- Example window rules that are useful

hl.window_rule({
	-- Ignore maximize requests from all apps. You'll probably like this.
	name = "suppress-maximize-events",
	match = { class = ".*" },

	suppress_event = "maximize",
})

hl.window_rule({
	-- Fix some dragging issues with XWayland
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},

	no_focus = true,
})

-- Hyprland-run windowrule
hl.window_rule({
	name = "move-hyprland-run",
	match = { class = "hyprland-run" },

	move = "20 monitor_h-120",
	float = true,
})

-- Prompts from scripts/ (workspace names, confirmations)
hl.window_rule({
	name = "float-zenity",
	match = { class = "zenity" },

	float = true,
})

-- Steam (XWayland) places its toasts at the raw screen corner, ignoring the
-- reserved area, so they end up under waybar (bottom, 38px). Nudge them up.
hl.window_rule({
	name = "steam-toasts-above-waybar",
	match = { class = "^steam$", title = "^notificationtoasts_.*$" },

	float = true,
	no_focus = true,
	move = "monitor_w-window_w monitor_h-window_h-38",
})

-- SwayOSD and the bar's popups (l1p0-menus and ~/.config/l1p0-menu/popups.py;
-- namespaces from `hyprctl layers`), one look for all of them. SwayOSD's window
-- is wider than the visible panel and transparent around it, so skip blur where
-- the alpha is below the panel's: that leaves the margin and the CSS shadow
-- unblurred.
hl.layer_rule({
	name = "popup-glass",
	match = { namespace = "^(swayosd|(audio|brightness|calendar|battery|network|pia|weather)-layer)$" },

	blur = true,
	ignore_alpha = 0.3,
	animation = "fade",
})

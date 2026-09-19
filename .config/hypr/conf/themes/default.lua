-- The original cyan/green Hyprland look. Also the fallback for any key another
-- theme leaves out, so every name below is always available.
return {
	name = "Default",

	background = "#1a1a1a", -- darkest layer: shadows, bar backgrounds
	surface = "#2a2a2a", -- raised layer: inactive tabs, panels
	foreground = "#ffffff", -- main text
	muted = "#a0a0a0", -- secondary text

	primary = "#33ccff", -- main accent: active border start, active tab
	secondary = "#00ff99", -- second accent: active border end
	highlight = "#ffcc33", -- attention: locked groups, urgent
	on_primary = "#101418", -- text drawn on top of primary/secondary

	border = "#33ccff", -- solid border for things that cannot take a gradient
	border_inactive = "#595959",

	success = "#00ff99",
	warning = "#ffcc33",
	error = "#ff5577",
}

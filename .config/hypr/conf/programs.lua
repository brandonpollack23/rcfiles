-- Set programs that you use
return {
	terminal = "ghostty",
	fileManager = "nautilus",
	menu = "hyprlauncher",
	desktop_bar = "waybar",
	notification_center = "swaync",
	lock = "hyprlock",
	idle = "hypridle",
	session = "hypr-persist",
	wallpaper = "awww-daemon",
	input_ime = "fcitx5 -d",
	-- Copies the pick and pastes it into the focused window. ydotool, not the
	-- autodetected wtype: wtype's private keymap breaks Hyprland's binds.
	emoji = "rofimoji --selector hyprlauncher --action clipboard --typer ydotool --clipboarder wl-copy",
	browser = "google-chrome-stable",
}

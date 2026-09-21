-- Set programs that you use
return {
	terminal = "ghostty",
	fileManager = "nautilus",
	menu = "hyprlauncher",
	desktop_bar = "waybar",
	-- The one process behind every scripted button in the bar; started just
	-- before it. See ~/.config/waybar/brpol-waybard/README.md.
	taskbar_daemon = "~/.config/waybar/brpol-waybard/scripts/launch.sh",
	notification_center = "swaync",
	-- Volume/brightness popup, styled by ~/.config/swayosd/style.css.
	osd = "swayosd-server",
	-- The popups behind the bar's status modules. launch.sh renders the config
	-- and style l1p0-menus reads, then runs its daemon.
	bar_popups = "~/.config/l1p0-menu/launch.sh",
	-- Night light; idle at a neutral temperature until the bar turns it on.
	nightlight = "hyprsunset",
	lock = "hyprlock",
	idle = "hypridle",
	-- Session save/restore. session.sh runs the hypr-persist daemon, after the
	-- login restore when it is passed `restore` (conf/workspaces/persist.lua).
	session = "~/.config/hypr/scripts/session.sh",
	wallpaper = "awww-daemon",
	input_ime = "fcitx5 -d",
	-- Copies the pick and pastes it into the focused window. ydotool, not the
	-- autodetected wtype: wtype's private keymap breaks Hyprland's binds.
	emoji = "rofimoji --selector hyprlauncher --action clipboard --typer ydotool --clipboarder wl-copy",
	browser = "google-chrome-stable",
}

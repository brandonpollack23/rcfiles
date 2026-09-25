-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Disable all Omarchy default bindings. Add your own in hypr/bindings.lua.
-- omarchy_default_bindings = false
--
-- Or disable only bindings for Omarchy's preinstalled apps/web apps while
-- keeping core window-manager bindings:
-- omarchy_preinstalled_bindings = false

-- Load Omarchy defaults.
require("default.hypr.omarchy")

-- GloView, the Mission Control-style overview (gloview-git from the AUR); its
-- bindings are in bindings.lua. Only where it's installed, so a machine
-- without it still loads the config.
local gloview = io.open("/usr/lib/gloview.so")
if gloview then
  gloview:close()
  hl.plugin.load("/usr/lib/gloview.so")
end

-- hyprfocus (hyprland-plugin-hyprfocus from the AUR) animates the window
-- taking focus; looknfeel.lua sets it up. Also only where it's installed.
local hyprfocus = io.open("/usr/lib/libhyprfocus.so")
if hyprfocus then
  hyprfocus:close()
  hl.plugin.load("/usr/lib/libhyprfocus.so")
end

-- Put your personal overrides in these files. They're loaded after Omarchy's
-- defaults so package updates can improve the defaults without rewriting your
-- ~/.config/hypr files.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.layouts")
require("hypr.workspaces")
require("hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- Add any other personal Hyprland configuration below.
-- o.window("qemu", { workspace = "5" })

-- Opaque windows everywhere: opt every window out of Omarchy's default
-- window opacity (0.985 focused, 0.96 not) and the browsers' 0.985 unfocused.
o.window(".*", { tag = "-default-opacity", opacity = "1 1" })

-- Tile Steam's main window and Friends List. Omarchy floats every Steam
-- window (default/hypr/apps/steam.lua); its dialogs still float.
o.window({ class = "steam", title = "^(Steam|Friends List)$" }, { tile = true })

-- Keep only your personal keybinding overrides here. Add new bindings with
-- o.bind or replace defaults with o.rebind.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding. o.rebind takes the same arguments as o.bind.
-- This example replaces the default file manager with Flea.
-- o.rebind("SUPER + SHIFT + F", "File manager", { launch = "flea" })

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Vim keys for windows: SUPER + hjkl focuses, SUPER + SHIFT + hjkl swaps, as
-- the arrows do. Unbind and bind rather than o.rebind, which Omarchy 4.0.4
-- doesn't have yet. What SUPER + J, K and L did moves below.
local vim_directions = { H = "l", J = "d", K = "u", L = "r" }
local vim_names = { H = "left", J = "down", K = "up", L = "right" }
for key, direction in pairs(vim_directions) do
  hl.unbind("SUPER + " .. key)
  o.bind("SUPER + " .. key, "Focus on " .. vim_names[key] .. " window", hl.dsp.focus({ direction = direction }))
  o.bind("SUPER + SHIFT + " .. key, "Swap window " .. vim_names[key], hl.dsp.window.swap({ direction = direction }))
end

o.bind("SUPER + ALT + J", "Toggle window split", hl.dsp.layout("togglesplit"))

-- SUPER + TAB and SUPER + SHIFT + TAB step through a group's windows, like
-- SUPER + ALT + TAB, instead of the workspaces; SUPER + CTRL + arrows do those.
hl.unbind("SUPER + TAB")
hl.unbind("SUPER + SHIFT + TAB")
o.bind("SUPER + TAB", "Next window in group", hl.dsp.group.next())
o.bind("SUPER + SHIFT + TAB", "Previous window in group", hl.dsp.group.prev())

-- SUPER + SHIFT + G locks or unlocks the focused group, next to SUPER + G that
-- makes it; a locked group's tabs and border turn red (looknfeel.lua). It was
-- Signal.
hl.unbind("SUPER + SHIFT + G")
o.bind("SUPER + SHIFT + G", "Toggle group lock", hl.dsp.group.lock_active())

-- SUPER + CTRL + G enters the "group" submap, shown on the bar in the locked
-- group red (the brandonpollack23.submap widget), until ESCAPE or ENTER:
--   H / L                 move the tab left / right within its group, then
--                         leave group mode 300ms after the last press
--   X                     take the window out of its group
--   SHIFT + H / SHIFT + L merge into the window on the left / right, making
--                         that one a group first if it isn't
local function merge_into_group(direction)
  local window = hl.get_active_window()
  if not window then
    return
  end
  hl.dispatch(hl.dsp.focus({ direction = direction }))
  local neighbor = hl.get_active_window()
  if not neighbor or neighbor.address == window.address then
    return
  end
  if not neighbor.group then
    hl.dispatch(hl.dsp.group.toggle())
  end
  hl.dispatch(hl.dsp.focus({ window = "address:" .. window.address }))
  hl.dispatch(hl.dsp.window.move({ into_group = direction }))
end

-- H and L restart the countdown, so pressing again keeps group mode open.
local leave_group_mode = require("hypr.bindings.helpers").restartable_timeout(500, function()
  if hl.get_current_submap() == "group" then
    hl.dispatch(hl.dsp.submap("reset"))
  end
end)

local function move_tab(forward)
  hl.dispatch(hl.dsp.group.move_window({ forward = forward }))
  leave_group_mode.restart()
end

o.bind("SUPER + CTRL + G", "Group mode", function()
  leave_group_mode.cancel()
  hl.dispatch(hl.dsp.submap("group"))
end)
hl.define_submap("group", function()
  o.bind("H", "Move tab left in group", function()
    move_tab(false)
  end)
  o.bind("L", "Move tab right in group", function()
    move_tab(true)
  end)
  o.bind("X", "Move window out of group", hl.dsp.window.move({ out_of_group = true }))
  o.bind("SHIFT + H", "Merge into group on left", function()
    merge_into_group("l")
  end)
  o.bind("SHIFT + L", "Merge into group on right", function()
    merge_into_group("r")
  end)
  o.bind("ESCAPE", "Leave group mode", hl.dsp.submap("reset"))
  o.bind("RETURN", "Leave group mode", hl.dsp.submap("reset"))
end)

-- SUPER + CTRL + arrows step through the open workspaces instead of a group's
-- windows; SUPER + TAB, SUPER + ALT + TAB and SUPER + ALT + 1-5 still do
-- those. Past the last one they make a new workspace (workspaces.lua).
hl.unbind("SUPER + CTRL + LEFT")
hl.unbind("SUPER + CTRL + RIGHT")
o.bind("SUPER + CTRL + LEFT", "Previous workspace", function()
  require("hypr.workspaces").step(-1)
end)
o.bind("SUPER + CTRL + RIGHT", "Next workspace", function()
  require("hypr.workspaces").step(1)
end)

-- Cycle the workspace through focus, work/reference, dwindle and scrolling
-- (layouts.lua) instead of Omarchy's dwindle/scrolling toggle.
o.bind("SUPER + ALT + L", "Cycle workspace layout", function()
  require("hypr.layouts").cycle()
end)

-- Yazi for the file manager instead of Nautilus, on SUPER + E as well. The
-- cwd one opens in the focused terminal's directory, as nautilus-cwd does;
-- { tui = ... } quotes its command whole, so that one is a plain string.
local yazi_cwd = 'omarchy-launch-tui yazi "$(omarchy-cmd-terminal-cwd)"'
hl.unbind("SUPER + SHIFT + F")
hl.unbind("SUPER + ALT + SHIFT + F")
o.bind("SUPER + SHIFT + F", "File manager", { tui = "yazi" })
o.bind("SUPER + E", "File manager", { tui = "yazi" })
o.bind("SUPER + ALT + SHIFT + F", "File manager (cwd)", yazi_cwd)

-- The Omarchy menu on SUPER + R too, where my old launcher was.
o.bind("SUPER + R", "Omarchy menu", "omarchy-menu toggle")

-- Keybindings on SUPER + ?, the help key, and Passwords from there to SUPER + I.
hl.unbind("SUPER + SHIFT + SLASH")
o.bind("SUPER + SHIFT + SLASH", "Keybindings", "omarchy-menu-keybindings")
-- Bitwarden, focused if it's already open. { omarchy = "x" } only runs
-- omarchy-launch-x, and Omarchy ships that for 1Password alone.
o.bind("SUPER + I", "Passwords", { launch = "bitwarden-desktop", focus = "^Bitwarden$" })

-- Google Calendar on SUPER + SHIFT + C instead of HEY's.
hl.unbind("SUPER + SHIFT + C")
o.bind("SUPER + SHIFT + C", "Calendar", { webapp = "https://calendar.google.com/" })

-- The emoji picker on SUPER + : as well as SUPER + CTRL + E. Binds match the
-- unshifted key, so that's SUPER + SHIFT + SEMICOLON.
o.bind("SUPER + SHIFT + SEMICOLON", "Emojis", "omarchy-shell shell toggle omarchy.emojis")

-- SUPER + $ names the workspace. Binds match the unshifted key, so that's
-- SUPER + SHIFT + 4, taken from Omarchy's move to workspace 4; SUPER + M, or
-- SUPER + ALT + M and SUPER + SHIFT + ALT + 4 without following the window,
-- still get there. SUPER + D picks any open workspace, the scratchpad too.
-- Omarchy binds the number row by keycode, and code:13 is the 4 key.
hl.unbind("SUPER + SHIFT + code:13")
o.bind("SUPER + SHIFT + code:13", "Name workspace", "hypr-workspace-menu rename")
o.bind("SUPER + D", "Go to a picked workspace", "hypr-workspace-menu go")
o.bind("SUPER + M", "Move window to a picked workspace", "hypr-workspace-menu move")
o.bind("SUPER + ALT + M", "Move window silently to a picked workspace", "hypr-workspace-menu move silent")
-- SUPER + N makes a named workspace where you pick, the end first, and SUPER +
-- SHIFT + N takes the window there. That was Omarchy's Editor. SUPER + ALT + N
-- makes a named hidden (special) workspace and shows it.
hl.unbind("SUPER + SHIFT + N")
o.bind("SUPER + N", "New workspace", "hypr-workspace-menu new")
o.bind("SUPER + SHIFT + N", "Move window to a new workspace", "hypr-workspace-menu new move")
o.bind("SUPER + ALT + N", "New hidden workspace", "hypr-workspace-menu new hidden")

-- Move to the scratchpad on SUPER + SHIFT + S, next to SUPER + S that shows
-- it, instead of Omarchy's SUPER + ALT + S. It replaces the Google Maps web app.
hl.unbind("SUPER + ALT + S")
hl.unbind("SUPER + SHIFT + S") -- was google maps.
o.bind(
  "SUPER + SHIFT + S",
  "Move window to scratchpad",
  hl.dsp.window.move({ workspace = "special:scratchpad", follow = false })
)

-- GloView (loaded in hyprland.lua): SUPER + SHIFT + D toggles the overview,
-- taken from Omarchy's Docker. The function looks the plugin up when the key
-- is pressed, since it may load after this, and says what to install when it
-- isn't there. SUPER + CTRL + arrows keep stepping workspaces while it's open
-- (workspaces.lua).
hl.unbind("SUPER + SHIFT + D")
o.bind("SUPER + SHIFT + D", "Overview", function()
  if not hl.plugin.gloview then
    hl.notification.create({
      text = "GloView isn't loaded: install it with `yay -S gloview-git` (or `mise run deps`), then reload Hyprland",
      timeout = 8000,
      icon = "error",
    })
    return
  end
  hl.plugin.gloview.toggle()
end)

-- Taskbar
o.bind("SUPER + CTRL + ALT + S", "Stocks/Market Ticker", "omarchy-shell costafot.markets toggle")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

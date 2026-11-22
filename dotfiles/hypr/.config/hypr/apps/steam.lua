-- Tile Steam's main window and Friends List. Omarchy floats every Steam
-- window (default/hypr/apps/steam.lua); its dialogs still float.
o.window({ class = "steam", title = "^(Steam|Friends List)$" }, { tile = true })

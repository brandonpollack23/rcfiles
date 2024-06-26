-- Tips:
-- Most stuff is what you expect with either a Super or a C-S-Alt prefix.
-- If you ever need to see the bindings, use `wezterm show-keys` in the terminal.

local wezterm = require('wezterm')

local config = wezterm.config_builder()

-- Appearance
config.color_scheme = 'Vs Code Dark+ (Gogh)'
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true



config.enable_scroll_bar = true

return config

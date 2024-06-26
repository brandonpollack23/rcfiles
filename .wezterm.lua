-- Tips:
-- Most stuff is what you expect with either a Super or a C-S-Alt prefix.
-- If you ever need to see the bindings, use `wezterm show-keys` in the terminal.
-- To copy or navigate enter copy mode which is C-S-x and uses vim motions.  y to yank.
-- Searching for text is done with C-S-F or Super-F
-- Tab prefix is Super-Shift {/} or number
--
-- TODO:
-- scrolling like in tmux (vim bindings)
-- searching like in tmux (vim bindigs)
-- copying while moving like in tmux
-- Naming tabs
-- Learn how to work iwth panes (rearrange, resize, etc)
--
-- Setting up ssh/sessions

local wezterm = require('wezterm')

local config = wezterm.config_builder()

-- Appearance
config.color_scheme = 'Vs Code Dark+ (Gogh)'
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.enable_scroll_bar = true
config.colors = {
  scrollbar_thumb = '#AAAAAA'
}

-- Keybindings
config.keys = {
  -- Panes
  {
    key = '|',
    mods = 'CTRL|ALT|SHIFT',
    action = wezterm.action { SplitHorizontal = { domain = "CurrentPaneDomain" } },
  },
  {
    key = '"',
    mods = 'CTRL|ALT|SHIFT',
    action = wezterm.action { SplitVertical = { domain = "CurrentPaneDomain" } },
  },
  {
    key = 'h',
    mods = 'CTRL|SHIFT',
    action = wezterm.action { ActivatePaneDirection = "Left" },
  },
  {
    key = 'l',
    mods = 'CTRL|SHIFT',
    action = wezterm.action { ActivatePaneDirection = "Right" },
  },
  {
    key = 'k',
    mods = 'CTRL|SHIFT',
    action = wezterm.action { ActivatePaneDirection = "Up" },
  },
  {
    key = 'j',
    mods = 'CTRL|SHIFT',
    action = wezterm.action { ActivatePaneDirection = "Down" },
  },
  -- Scrolling/Movement
  {
    key = 'u',
    mods = 'SUPER',
    action = wezterm.action { ScrollByPage = -1 },
  },
  {
    key = 'd',
    mods = 'SUPER',
    action = wezterm.action { ScrollByPage = 1 },
  },
  {
    key = 'j',
    mods = 'SUPER',
    action = wezterm.action.ScrollByLine(1),
  },
  {
    key = 'j',
    mods = 'SUPER',
    action = wezterm.action.ScrollByLine(1),
  },
  -- Tabs
  {
    key = ']',
    mods = 'SUPER|SHIFT',
    action = wezterm.action { ActivateTabRelative = 1 },
  },
  {
    key = '[',
    mods = 'SUPER|SHIFT',
    action = wezterm.action { ActivateTabRelative = 1 },
  },
  -- Command Palette
  {
    key = 'p',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.ActivateCommandPalette,
  },
}

return config

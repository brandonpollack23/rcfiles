-- Tips:
-- Most stuff is what you expect with either a Super or a C-S-Alt prefix.
-- If you ever need to see the bindings, use `wezterm show-keys` in the terminal.
-- To copy or navigate enter copy mode which is C-S-x and uses vim motions.  y to yank.
-- Searching for text is done with C-S-F or Super-F
-- Tab prefix is Super-Shift {/} or number
--
-- TODO:
-- Set tab title quick bind that doesnt require a prompt (right now it is wezterm cli set-tab-title)
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

-- Hyperlinks
config.hyperlink_rules = wezterm.default_hyperlink_rules()
-- Github issues like TODO[abc123/abc123#424242]
table.insert(config.hyperlink_rules, {
  regex = [=[TODO(\[|\()([-A-Za-z0-9]+)\/([-A-Za-z0-9]+)\#([0-9]+)(\]|)]=],
  format = 'https://www.github.com/$2/$3/issues/$4',
  hightlight = 1,
})
-- Github links
table.insert(config.hyperlink_rules, {
  regex = [[["]?([\w\d]{1}[-\w\d]+)(/){1}([-\w\d\.]+)["]?]],
  format = 'https://www.github.com/$1/$3',
})

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

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
config.tab_bar_at_bottom = true
config.enable_scroll_bar = true
config.enable_kitty_graphics = true
config.colors = {
  scrollbar_thumb = '#AAAAAA',

  tab_bar = {
    background = '#FF0000',
    active_tab = {
      bg_color = '#FFBB00',
      fg_color = '#000000',
      underline = 'Single',
      italic = true,
    },
    inactive_tab = {
      bg_color = '#FF0000',
      fg_color = '#FFFFFF',
    },
    inactive_tab_hover = {
      bg_color = '#AA0000',
      fg_color = '#FFFFFF',
      italic = true
    },
    new_tab = {
      bg_color = '#FF0000',
      fg_color = '#FFFFFF',
    },
    new_tab_hover = {
      bg_color = '#AA0000',
      fg_color = '#FFFFFF',
      italic = true
    },
  }
}

-- Asterisk on tab title
local function tab_title(tab_info)
  local title = tab_info.tab_title
  -- if the tab title is explicitly set, take that
  if title and #title > 0 then
    return title
  end
  -- Otherwise, use the title from the active pane
  -- in that tab
  return tab_info.active_pane.title
end

-- wezterm.on(
--   'format-tab-title',
--   function(tab, tabs, panes, config, hover, max_width)
--     local title = tab_title(tab)
--     if tab.is_active then
--       return {
--         { Text = ' ' .. title .. '* ' },
--       }
--     end
--     return title
--   end
-- )

-- Hyperlinks
config.hyperlink_rules = wezterm.default_hyperlink_rules()
-- Github issues like TODO[abc123/abc123#424242]
table.insert(config.hyperlink_rules, {
  regex = [=[TODO(\[|\()([-A-Za-z0-9]+)\/([-A-Za-z0-9]+)\#([0-9]+)(\]|)]=],
  format = 'https://www.github.com/$2/$3/issues/$4',
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

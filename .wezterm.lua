-- Tips:
-- Most stuff is what you expect with either a Super or a C-S-Alt prefix.
-- If you ever need to see the bindings, use `wezterm show-keys` in the terminal.
-- To copy or navigate enter copy mode which is C-S-x and uses vim motions.  y to yank.
-- Searching for text is done with C-S-F or Super-F
-- Tab prefix is Super-Shift {/} or number
-- Ctrl-G closes launcher menu (like emacs)

local wezterm = require('wezterm')

local config = wezterm.config_builder()

-- Only run if wezterm.local.lua exists
-- To have one, put it in $HOME/.config/wezterm/local_wezterm.lua
local ok, local_wezterm = pcall(require, 'local_wezterm')
if ok then
  wezterm.log_info('Loaded local_wezterm.lua')
  local_wezterm.load(config)
end

-- use my alias wezconl to connect.
config.unix_domains = {
  { name = 'local_wez_domain' }
}

if wezterm.target_triple == 'x86_64-pc-windows-msvc' then
  -- Windows, set domain to Manjaro.
  config.default_domain = 'WSL:Manjaro'
end

-- disable ligatures
config.harfbuzz_features = { "calt=0", "clig=0", "liga=0" }

-- Window features
config.window_close_confirmation = 'AlwaysPrompt'
config.skip_close_confirmation_for_processes_named = {}

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

-- Window name format
local function window_title(tab, pane)
  local title = tab.active_pane.title
  if title and #title > 0 then
    title = '[' .. pane.domain_name .. ']' .. ' - ' .. title
    return title
  else
    return "BLARG"
  end
end
wezterm.on('format-window-title', window_title)

-- Tab name format
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
wezterm.on(
  'format-tab-title',
  function(tab, tabs, panes, config, hover, max_width)
    local title = tab_title(tab)
    return {
      { Text = ' ' .. title .. ' ' },
    }
  end
)

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

-- Configure SSH Domains from the ~/.ssh/config file
config.ssh_domains = wezterm.default_ssh_domains()
for _, dom in ipairs(config.ssh_domains) do
  dom.assume_shell = 'Posix'
end

-- Custom functions
local function prompt_tab_title()
  return wezterm.action.PromptInputLine {
    description = wezterm.format {
      { Attribute = { Intensity = 'Bold' } },
      { Text = 'New Tab Name' },
    },
    action = wezterm.action_callback(function(window, pane, line)
      if line then
        local tab = window:active_tab()
        tab:set_title(line)
      end
    end)
  }
end

local function prompt_workspace_title()
  return wezterm.action.PromptInputLine {
    description = wezterm.format {
      { Attribute = { Intensity = 'Bold' } },
      { Text = 'New Workspace Name' },
    },
    action = wezterm.action_callback(function(window, pane, line)
      if line then
        local workspace = window:active_workspace()
        workspace:set_title(line)
      end
    end)
  }
end

-- TODO(wez/wezterm#3658) Until wezterm implements this itself, I use the CLI to do this.
local function kill_workspace(workspace)
  return wezterm.action.PromptInputLine {
    description = wezterm.format {
      { Attribute = { Intensity = 'Bold' } },
      { Text = 'Are you sure you want to kill this workspace? (y or Esc to cancel)' },
    },
    action = wezterm.action_callback(function(window, pane, line)
      if line == 'y' then
        workspace = workspace or window:get_active_workspace()
        local success, stdout = wezterm.run_child_process({ "wezterm", "cli", "list",
          "--format=json" })

        if success then
          local json = wezterm.json_parse(stdout)
          if not json then
            return
          end

          local workspace_panes = u.filter(json, function(p)
            return p.workspace == workspace
          end)

          for _, p in ipairs(workspace_panes) do
            wezterm.run_child_process({ "wezterm", "cli", "kill-pane", "--pane-id=" ..
            p.pane_id })
          end
        end
      end
    end)
  }
end

local function select_domain_action(pane)
  local domains = wezterm.mux.all_domains()
  local domain_names = {}
  for _, domain in ipairs(domains) do
    if domain:name() ~= pane:get_domain_name() then
      -- Skip the current domain
      table.insert(domain_names, { label = domain:name() })
    end
  end

  return wezterm.action.InputSelector {
    action = wezterm.action_callback(function(window, pane, id, label)
      if not id and not label then
        wezterm.log_info('cancelled domain selection')
      else
        wezterm.log_info('selected domain', label)
        for _, domain in ipairs(domains) do
          if domain:name() == label then
            wezterm.log_info('Window ', window:window_id(), ' Attaching to domain ', domain:name())
            wezterm.mux.spawn_window({
              domain = { DomainName = domain:name() },
            })
            return
          end
        end
        wezterm.log_error('No domain found with name', label)
      end
    end),
    title = 'Choose Domain',
    choices = domain_names,
    fuzzy = true,
  }
end

wezterm.on('augment-command-palette', function(window, pane)
  return {
    {
      brief = 'Attach to a domain',
      action = select_domain_action(pane),
    },
  }
end)

-- Keybindings
config.leader = { key = 'a', mods = 'CTRL' }
config.keys = {
  -- Domains (like sessions)
  {
    key = 'a', --attach to domains (usually populated from sshconfig)
    mods = 'CTRL|SHIFT',
    action = wezterm.action.ShowLauncherArgs { flags = "FUZZY|DOMAINS" }
  },
  {
    key = 'd',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.DetachDomain('CurrentPaneDomain')
  },
  -- Tabs/Workspaces
  {
    key = ',',
    mods = 'CTRL|ALT',
    action = prompt_tab_title()
  },
  {
    key = ';',
    mods = 'CTRL|ALT',
    action = prompt_workspace_title()
  },
  {
    key = 't',
    mods = 'CTRL|ALT',
    action = wezterm.action.ShowLauncherArgs { flags = "FUZZY|TABS" }
  },
  {
    key = 'q', -- Create a new workspace with a random name.
    mods = 'CTRL|SHIFT',
    action = wezterm.action.SwitchToWorkspace {}
  },
  {
    key = 'z',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.ShowLauncherArgs { flags = "FUZZY|WORKSPACES" }
  },
  {
    key = 'x',
    mods = 'CTRL|ALT',
    action = kill_workspace()
  },
  -- Panes
  {
    key = 'x',
    mods = 'CTRL|SHIFT',
    action = wezterm.action { CloseCurrentPane = { confirm = true } },
  },
  {
    key = '|',
    mods = 'CTRL|ALT|SHIFT',
    action = wezterm.action { SplitHorizontal = { domain = "CurrentPaneDomain" } },
  },
  {
    key = '\\',
    mods = 'LEADER',
    action = wezterm.action { SplitHorizontal = { domain = "CurrentPaneDomain" } },
  },
  {
    key = "'",
    mods = 'CTRL|ALT|SHIFT',
    action = wezterm.action { SplitVertical = { domain = "CurrentPaneDomain" } },
  },
  {
    key = "'",
    mods = 'LEADER',
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
    key = 'J',
    mods = 'CTRL|SHIFT',
    action = wezterm.action { ActivatePaneDirection = "Down" },
  },
  {
    key = 'h',
    mods = 'LEADER',
    action = wezterm.action { ActivatePaneDirection = "Left" },
  },
  {
    key = 'l',
    mods = 'LEADER',
    action = wezterm.action { ActivatePaneDirection = "Right" },
  },
  {
    key = 'k',
    mods = 'LEADER',
    action = wezterm.action { ActivatePaneDirection = "Up" },
  },
  {
    key = 'j',
    mods = 'LEADER',
    action = wezterm.action { ActivatePaneDirection = "Down" },
  },
  {
    key = 'h',
    mods = 'CTRL|ALT|SHIFT',
    action = wezterm.action.AdjustPaneSize { 'Left', 5 }
  },
  {
    key = 'l',
    mods = 'CTRL|ALT|SHIFT',
    action = wezterm.action.AdjustPaneSize { 'Right', 5 }
  },
  {
    key = 'k',
    mods = 'CTRL|ALT|SHIFT',
    action = wezterm.action.AdjustPaneSize { 'Up', 5 }
  },
  {
    key = 'j',
    mods = 'CTRL|ALT|SHIFT',
    action = wezterm.action.AdjustPaneSize { 'Down', 5 }
  },
  {
    key = 'h',
    mods = 'LEADER|ALT',
    action = wezterm.action.AdjustPaneSize { 'Left', 5 }
  },
  {
    key = 'l',
    mods = 'LEADER|ALT',
    action = wezterm.action.AdjustPaneSize { 'Right', 5 }
  },
  {
    key = 'k',
    mods = 'LEADER|ALT',
    action = wezterm.action.AdjustPaneSize { 'Up', 5 }
  },
  {
    key = 'j',
    mods = 'LEADER|ALT',
    action = wezterm.action.AdjustPaneSize { 'Down', 5 }
  },
  -- Scrolling/Movement
  {
    key = 'U',
    mods = 'CTRL|SHIFT',
    action = wezterm.action { ScrollByPage = -1 },
  },
  {
    key = 'D',
    mods = 'CTRL|SHIFT',
    action = wezterm.action { ScrollByPage = 1 },
  },
  {
    key = 'K',
    mods = 'ALT|SHIFT',
    action = wezterm.action.ScrollByLine(-1),
  },
  {
    key = 'J',
    mods = 'ALT|SHIFT',
    action = wezterm.action.ScrollByLine(1),
  },
  {
    key = '{',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.ActivateCopyMode,
  },
  -- Tabs
  {
    key = ']',
    mods = 'CTRL|ALT',
    action = wezterm.action { ActivateTabRelative = 1 },
  },
  {
    key = '[',
    mods = 'CTRL|ALT',
    action = wezterm.action { ActivateTabRelative = -1 },
  },
  {
    key = 'H',
    mods = 'LEADER',
    action = wezterm.action { MoveTabRelative = -1 },
  },
  {
    key = 'L',
    mods = 'LEADER',
    action = wezterm.action { MoveTabRelative = 1 },
  },
  -- Command Palette
  {
    key = 'p',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.ActivateCommandPalette,
  },
  -- GUI Window Controls
  {
    key = 'f',
    mods = 'CTRL|ALT|SHIFT',
    action = wezterm.action.ToggleFullScreen,
  },
}

return config

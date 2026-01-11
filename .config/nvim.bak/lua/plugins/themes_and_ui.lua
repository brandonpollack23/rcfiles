return {
  {
    'Mofiqul/vscode.nvim',
    priority = 2000,
    config = function()
      -- Lua:
      -- For dark theme (neovim's default)
      vim.o.background = 'dark'

      local c = require('vscode.colors').get_colors()
      require('vscode').setup({
        -- Alternatively set style in setup
        -- style = 'light'

        -- Enable transparent background
        transparent = false,

        -- Enable italic comment
        italic_comments = true,

        -- Underline `@markup.link.*` variants
        underline_links = true,

        -- Disable nvim-tree background color
        disable_nvimtree_bg = true,

        -- Override colors (see ./lua/vscode/colors.lua)
        color_overrides = {},

        -- Override highlight groups (see ./lua/vscode/theme.lua)
        group_overrides = {
          -- this supports the same val table as vim.api.nvim_set_hl
          -- use colors from this colorscheme by requiring vscode.colors!
          Cursor = { fg = c.vscDarkBlue, bg = c.vscLightGreen, bold = true },
        }
      })

      require('vscode').load()
    end
  },
  -- Pretty status line
  {
    'nvim-lualine/lualine.nvim',
    dependencies = {
      'Mofiqul/vscode.nvim',
      'arkav/lualine-lsp-progress',
      'f-person/git-blame.nvim',
      'linrongbin16/lsp-progress.nvim',
      'nvim-tree/nvim-web-devicons',
    },
    cond = not vim.g.started_by_firenvim,
    config = function()
      local git_blame = require('gitblame')
      require('lualine').setup {
        options = {
          icons_enabled = true,
          theme = 'auto',
          component_separators = { left = '', right = '' },
          section_separators = { left = '', right = '' },
          disabled_filetypes = {
            statusline = {},
            winbar = {},
          },
          ignore_focus = {},
          always_divide_middle = true,
          globalstatus = false,
          refresh = {
            statusline = 1000,
            tabline = 1000,
            winbar = 1000,
          }
        },
        sections = {
          lualine_a = { 'mode' },
          lualine_b = { 'branch', 'diff', 'diagnostics' },
          lualine_c = {
            { 'filename',                       path = 1 },
            { git_blame.get_current_blame_text, cond = git_blame.is_blame_text_available },
            'lsp_progress',
          },
          lualine_x = {
            'encoding',
            'fileformat',
            'filetype'
          },
          lualine_y = { 'progress' },
          lualine_z = { 'location' }
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = { 'filename' },
          lualine_x = { 'location' },
          lualine_y = {},
          lualine_z = {}
        },
        tabline = {},
        winbar = {},
        inactive_winbar = {},
        extensions = {}
      }

      -- listen lsp-progress event and refresh lualine
      vim.api.nvim_create_augroup('lualine_augroup', { clear = true })
      vim.api.nvim_create_autocmd('User', {
        group = 'lualine_augroup',
        pattern = 'LspProgressStatusUpdated',
        callback = require('lualine').refresh,
      })
    end
  },
  {
    'linrongbin16/lsp-progress.nvim',
    config = function()
      require('lsp-progress').setup()
    end
  },

  -- Buffer line aka tabs
  {
    'akinsho/bufferline.nvim',
    dependencies = 'nvim-tree/nvim-web-devicons',
    config = function()
      local bufferline = require('bufferline')
      bufferline.setup {
        options = {
          middle_mouse_command = 'bdelete! %d',
          right_mouse_command = nil,
          buffer_close_icon = '',
          sort_by = 'insert_at_end',
          diagnostics = 'nvim_lsp',
          color_icons = true,
          separator_style = 'slope',
          custom_filter = function() return true end, -- show all buffer types
        }
      }

      require('bufferline.groups').builtin.pinned:with({ icon = '' })

      local wk = require('which-key')
      wk.add({
        -- Buffer management
        { '<leader>b',   group = 'Buffers/Tabs' },
        { '<leader>bp',  ':BufferLineTogglePin<cr>',                       desc = 'Pin Buffer' },
        { '<leader>bn',  ':BufferLineCycleNext<cr>',                       desc = 'Next buffer' },
        { '<leader>bN',  ':BufferLineCyclePrev<cr>',                       desc = 'Previous buffer' },
        { '<leader>bl',  ':BufferLineMoveNext<cr>',                        desc = 'Move Right' },
        { '<leader>bh',  ':BufferLineMovePrev<cr>',                        desc = 'Move Left' },
        { '<leader>bL',  function() require('bufferline').move_to(-1) end, desc = 'Move to beginning' },
        { '<leader>bH',  function() require('bufferline').move_to(1) end,  desc = 'Move to end' },
        { '<leader>bx',  ':bdelete<cr>',                                   desc = 'Close Current buffer' },

        -- Close operations subgroup
        { '<leader>bX',  group = 'Close' },
        { '<leader>bXo', ':BufferLineCloseOthers<cr>',                     desc = 'Close other buffers' },
        { '<leader>bXL', ':BufferLineCloseRight<cr>',                      desc = 'Close all to the right' },
        { '<leader>bXH', ':BufferLineCloseLeft<cr>',                       desc = 'Close all to the Left' },

        -- Buffer picking
        { '<leader>B',   ':BufferLinePick<cr>',                            desc = 'Pick buffer' },

        -- vim-style buffer navigation
        { 'gt',          ':BufferLineCycleNext<cr>',                       desc = 'Next buffer' },
        { 'gT',          ':BufferLineCyclePrev<cr>',                       desc = 'Previous buffer' },
      })
    end
  },

  -- Smooth scrolling
  {
    'karb94/neoscroll.nvim',
    config = function()
      vim.keymap.set('n', '<C-u>', '<C-u>zz', { noremap = true })
      vim.keymap.set('n', '<C-d>', '<C-d>zz', { noremap = true })
      require('neoscroll').setup {}
    end
  },

  -- Scope indication lines
  {
    'lukas-reineke/indent-blankline.nvim',
    main = 'ibl',
    opts = {},
    config = function()
      vim.cmd('hi IblIndent guifg=#333333')
      vim.cmd('hi IblWhitespace guifg=#333333')
      vim.cmd('hi IblScope guifg=#3F3F3F')

      require('ibl').setup(
        {
          exclude = { filetypes = { 'help', 'dashboard' } },
        })
    end
  },
  {
    '3rd/image.nvim',
    dependencies = { 'leafo/magick' },
    config = function()
      require('image').setup({
        backend = 'kitty',
        -- Cant get this shit working
        -- processor = 'magick_rock',
        processor = 'magick_cli',
        integrations = {
          markdown = {
            enabled = true,
            clear_in_insert_mode = false,
            download_remote_images = true,
            only_render_image_at_cursor = false,
            filetypes = { 'markdown', 'vimwiki' }, -- markdown extensions (ie. quarto) can go here
          },
          neorg = {
            enabled = true,
            clear_in_insert_mode = false,
            download_remote_images = true,
            only_render_image_at_cursor = false,
            filetypes = { 'norg' },
          },
          html = {
            enabled = false,
          },
          css = {
            enabled = false,
          },
        },
        max_width = 150,
        max_height = 15,
        max_width_window_percentage = math.huge,
        max_height_window_percentage = math.huge,
        window_overlap_clear_enabled = true,                                                -- toggles images when windows are overlapped
        window_overlap_clear_ft_ignore = { 'cmp_menu', 'cmp_docs', '' },
        editor_only_render_when_focused = false,                                            -- auto show/hide images when the editor gains/looses focus
        tmux_show_only_in_active_window = false,                                            -- auto show/hide images in the correct Tmux window (needs visual-activity off)
        hijack_file_patterns = { '*.png', '*.jpg', '*.jpeg', '*.gif', '*.webp', '*.avif' }, -- render image files as images when opened
      })
    end
  },

  -- Pretty notifications with Noice
  -- configures command line, messages, popupmenu, commands history, notifications, etc
  -- https://github.com/folke/noice.nvim?tab=readme-ov-file#%EF%B8%8F-configuration
  {
    'folke/noice.nvim',
    event = 'VeryLazy',
    cond = not vim.g.started_by_firenvim,
    opts = {},
    dependencies = {
      -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
      'MunifTanjim/nui.nvim',
      -- OPTIONAL:
      --   `nvim-notify` is only needed, if you want to use the notification view.
      --   If not available, we use `mini` as the fallback
      'rcarriga/nvim-notify',
      'hrsh7th/nvim-cmp',
    },
    config = function()
      local notify = require('notify')
      notify.setup({
        background_colour = '#000000',
      })
      -- notify.setup({
      --     -- render = 'compact',
      --     timeout = 4000,
      --     fps = 10, -- default is 30
      --     stages = 'static',
      --   })
      require('noice').setup({
        -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
        override = {
          ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
          ['vim.lsp.util.stylize_markdown'] = true,
          ['cmp.entry.get_documentation'] = true, -- requires hrsh7th/nvim-cmp
        },
        presets = {
          bottom_search = true,         -- use a classic bottom cmdline for search
          command_palette = true,       -- position the cmdline and popupmenu together
          long_message_to_split = true, -- long messages will be sent to a split
          inc_rename = false,           -- enables an input dialog for inc-rename.nvim
          lsp_doc_border = false,       -- add a border to hover docs and signature help
        },
        lsp = {
          signature = {
            enabled = false,
            trigger = false,
            luasnip = false,
          },
        },
        -- notify = {
        --   enable = false,
        -- },
        views = {
          cmdline_popup = {
            position = {
              row = 5,
              col = '50%',
            },
            size = {
              width = 60,
              height = 'auto',
            },
          },
          popupmenu = {
            relative = 'editor',
            position = {
              row = 16,
              col = '50%',
            },
            size = {
              width = 60,
              height = 10,
            },
            border = {
              style = 'rounded',
              padding = { 0, 1 },
            },
            win_options = {
              winhighlight = { Normal = 'Normal', FloatBorder = 'DiagnosticInfo' },
            },
          },
        },
      })

      -- Add a keybinding to open noice errors with telescope
      require('which-key').add({
        { '<leader>n',  group = 'LSP/IDE Operations' },
        { '<leader>ne', ':Telescope noice<cr>',                                           desc = 'Show messages history' },
        { '<leader>nd', function() notify.dismiss({ silent = true, pending = true }) end, desc = 'Dismiss notifications' },
      })
      --
    end
  },

  -- Pretty scrollbar with information.
  -- {
  --   'lewis6991/satellite.nvim',
  --   dependencies = { 'lewis6991/gitsigns.nvim' },
  --   config = function()
  --     require('satellite').setup({
  --       current_only = false,
  --       winblend = 50,
  --       zindex = 40,
  --       excluded_filetypes = {},
  --       width = 16,
  --       handlers = {
  --         cursor = {
  --           enable = true,
  --           -- Supports any number of symbols
  --           symbols = { '⎺', '⎻', '⎼', '⎽' }
  --           -- symbols = { '⎻', '⎼' }
  --           -- Highlights:
  --           -- - SatelliteCursor (default links to NonText
  --         },
  --         search = {
  --           enable = true,
  --           -- Highlights:
  --           -- - SatelliteSearch (default links to Search)
  --           -- - SatelliteSearchCurrent (default links to SearchCurrent)
  --         },
  --         diagnostic = {
  --           enable = true,
  --           signs = { '-', '=', '≡' },
  --           min_severity = vim.diagnostic.severity.HINT,
  --           -- Highlights:
  --           -- - SatelliteDiagnosticError (default links to DiagnosticError)
  --           -- - SatelliteDiagnosticWarn (default links to DiagnosticWarn)
  --           -- - SatelliteDiagnosticInfo (default links to DiagnosticInfo)
  --           -- - SatelliteDiagnosticHint (default links to DiagnosticHint)
  --         },
  --         gitsigns = {
  --           enable = true,
  --           signs = { -- can only be a single character (multibyte is okay)
  --             add = '│',
  --             change = '│',
  --             delete = '-',
  --           },
  --           -- Highlights:
  --           -- SatelliteGitSignsAdd (default links to GitSignsAdd)
  --           -- SatelliteGitSignsChange (default links to GitSignsChange)
  --           -- SatelliteGitSignsDelete (default links to GitSignsDelete)
  --         },
  --         marks = {
  --           enable = true,
  --           show_builtins = false, -- shows the builtin marks like [ ] < >
  --           key = 'm'
  --           -- Highlights:
  --           -- SatelliteMark (default links to Normal)
  --         },
  --         quickfix = {
  --           signs = { '-', '=', '≡' },
  --           -- Highlights:
  --           -- SatelliteQuickfix (default links to WarningMsg)
  --         }
  --       },
  --     })
  --   end
  -- },
  -- VScode like minimap
  {
    'Isrothy/neominimap.nvim',
    dependencies = { 'lewis6991/gitsigns.nvim', 'nvim-treesitter/nvim-treesitter' },
    version = 'v3.x.x',
    lazy = false, -- NOTE: NO NEED to Lazy load
    keys = {
      -- Global Minimap Controls
      { '<leader>mm',  '<cmd>Neominimap Toggle<cr>',      desc = 'Toggle global minimap' },
      { '<leader>mo',  '<cmd>Neominimap Enable<cr>',      desc = 'Enable global minimap' },
      { '<leader>mc',  '<cmd>Neominimap Disable<cr>',     desc = 'Disable global minimap' },
      { '<leader>mr',  '<cmd>Neominimap Refresh<cr>',     desc = 'Refresh global minimap' },

      -- Window-Specific Minimap Controls
      { '<leader>mwt', '<cmd>Neominimap WinToggle<cr>',   desc = 'Toggle minimap for current window' },
      { '<leader>mwr', '<cmd>Neominimap WinRefresh<cr>',  desc = 'Refresh minimap for current window' },
      { '<leader>mwo', '<cmd>Neominimap WinEnable<cr>',   desc = 'Enable minimap for current window' },
      { '<leader>mwc', '<cmd>Neominimap WinDisable<cr>',  desc = 'Disable minimap for current window' },

      -- Tab-Specific Minimap Controls
      { '<leader>mtt', '<cmd>Neominimap TabToggle<cr>',   desc = 'Toggle minimap for current tab' },
      { '<leader>mtr', '<cmd>Neominimap TabRefresh<cr>',  desc = 'Refresh minimap for current tab' },
      { '<leader>mto', '<cmd>Neominimap TabEnable<cr>',   desc = 'Enable minimap for current tab' },
      { '<leader>mtc', '<cmd>Neominimap TabDisable<cr>',  desc = 'Disable minimap for current tab' },

      -- Buffer-Specific Minimap Controls
      { '<leader>mbt', '<cmd>Neominimap BufToggle<cr>',   desc = 'Toggle minimap for current buffer' },
      { '<leader>mbr', '<cmd>Neominimap BufRefresh<cr>',  desc = 'Refresh minimap for current buffer' },
      { '<leader>mbo', '<cmd>Neominimap BufEnable<cr>',   desc = 'Enable minimap for current buffer' },
      { '<leader>mbc', '<cmd>Neominimap BufDisable<cr>',  desc = 'Disable minimap for current buffer' },

      ---Focus Controls
      { '<leader>mf',  '<cmd>Neominimap Focus<cr>',       desc = 'Focus on minimap' },
      { '<leader>mu',  '<cmd>Neominimap Unfocus<cr>',     desc = 'Unfocus minimap' },
      { '<leader>ms',  '<cmd>Neominimap ToggleFocus<cr>', desc = 'Switch focus on minimap' },
    },
    init = function()
      -- The following options are recommended when layout == "float"
      vim.opt.wrap = false
      vim.opt.sidescrolloff = 36 -- Set a large value

      --- Put your configuration here
      ---@type Neominimap.UserConfig
      vim.g.neominimap = {
        auto_enable = true,
        delay = 1000,
        click = {
          enable = true,
        },
        mark = {
          enable = true,
        },
        search = {
          enable = true,
        },
      }

      -- Make the warning highlight slightly less harsh
      vim.api.nvim_set_hl(0, 'NeominimapWarnLine', { bg = '#303000' })
      vim.api.nvim_set_hl(0, 'NeominimapInfoLine', { bg = '#235e8f' })
    end,
  },
  {
    'MeanderingProgrammer/render-markdown.nvim',
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.nvim' }, -- if you use the mini.nvim suite
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' }, -- if you use standalone mini plugins
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {},
  }
}

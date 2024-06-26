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
      'nvim-tree/nvim-web-devicons',
      'linrongbin16/lsp-progress.nvim',
      'Mofiqul/vscode.nvim',
      -- 'folke/noice.nvim'
    },
    cond = not vim.g.started_by_firenvim,
    config = function()
      CopilotEnabled = CopilotEnabled or false
      local function copilot_status()
        if CopilotEnabled then
          return 'Copilot: '
        else
          return 'Copilot: 😞'
        end
      end

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
            function()
              -- if require('noice').api.statusline.mode.has() then
              --   return require('noice').api.statusline.mode.get()
              -- else
              --   return ''
              -- end
            end,
            'filename',
            require('lsp-progress').progress,
          },
          lualine_x = {
            copilot_status,
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
      wk.register(
        {
          b = {
            name = 'Buffers/Tabs',
            p = { ':BufferLineTogglePin<cr>', 'Pin Buffer' },
            n = { ':BufferLineCycleNext<cr>', 'Next buffer' },
            N = { ':BufferLineCyclePrev<cr>', 'Previous buffer' },
            l = { ':BufferLineMoveNext<cr>', 'Move Right' },
            h = { ':BufferLineMovePrev<cr>', 'Move Left' },
            L = { function() require('bufferline').move_to(-1) end, 'Move to beginning' },
            H = { function() require('bufferline').move_to(1) end, 'Move to end' },
            x = { ':bdelete<cr>', 'Close Current buffer' },
            X = {
              name = 'Close',
              o = { ':BufferLineCloseOthers<cr>', 'Close other buffers' },
              L = { ':BufferLineCloseRight<cr>', 'Close all to the right' },
              H = { ':BufferLineCloseLeft<cr>', 'Close all to the Left' },
            }
          },
          ['<leader>B'] = { ':BufferLinePick<cr>', 'Pick buffer' },
        },
        {
          prefix = '<leader>',
        }
      )
      wk.register(
        {
          gt = { ':BufferLineCycleNext<cr>', 'Next buffer' },
          gT = { ':BufferLineCyclePrev<cr>', 'Previous buffer' },
        },
        {}
      )
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
      require('ibl').setup()

      -- Set an autocommand that disables the scope lines on dashboard files
      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('user-indent-blankline', { clear = true }),
        pattern = { 'dashboard' },
        callback = function()
          vim.cmd('IBLDisable')
        end,
      })
    end
  },
  {
    '3rd/image.nvim',
    config = function()
      require('image').setup()
    end
  }

  -- Pretty notifications with Noice
  -- configures command line, messages, popupmenu, commands history, notifications, etc
  -- https://github.com/folke/noice.nvim?tab=readme-ov-file#%EF%B8%8F-configuration
  -- {
  --   'folke/noice.nvim',
  --   event = 'VeryLazy',
  --   cond = not vim.g.started_by_firenvim,
  --   opts = {},
  --   dependencies = {
  --     -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
  --     'MunifTanjim/nui.nvim',
  --     -- OPTIONAL:
  --     --   `nvim-notify` is only needed, if you want to use the notification view.
  --     --   If not available, we use `mini` as the fallback
  --     'rcarriga/nvim-notify',
  --     'hrsh7th/nvim-cmp',
  --   },
  --   config = function()
  --     require('notify').setup({
  --       -- render = 'compact',
  --       timeout = 4000,
  --       fps = 10, -- default is 30
  --       stages = 'static',
  --     })
  --     require('noice').setup({
  --       -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
  --       override = {
  --         ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
  --         ['vim.lsp.util.stylize_markdown'] = true,
  --         ['cmp.entry.get_documentation'] = true, -- requires hrsh7th/nvim-cmp
  --       },
  --       presets = {
  --         bottom_search = true,         -- use a classic bottom cmdline for search
  --         command_palette = true,       -- position the cmdline and popupmenu together
  --         long_message_to_split = true, -- long messages will be sent to a split
  --         inc_rename = false,           -- enables an input dialog for inc-rename.nvim
  --         lsp_doc_border = false,       -- add a border to hover docs and signature help
  --       },
  --       lsp = {
  --         signature = {
  --           enabled = false,
  --           trigger = false,
  --           luasnip = false,
  --         },
  --       },
  --       notify = {
  --         enable = false,
  --       },
  --       views = {
  --         cmdline_popup = {
  --           position = {
  --             row = 5,
  --             col = '50%',
  --           },
  --           size = {
  --             width = 60,
  --             height = 'auto',
  --           },
  --         },
  --         popupmenu = {
  --           relative = 'editor',
  --           position = {
  --             row = 16,
  --             col = '50%',
  --           },
  --           size = {
  --             width = 60,
  --             height = 10,
  --           },
  --           border = {
  --             style = 'rounded',
  --             padding = { 0, 1 },
  --           },
  --           win_options = {
  --             winhighlight = { Normal = 'Normal', FloatBorder = 'DiagnosticInfo' },
  --           },
  --         },
  --       },
  --     })
  --
  --     -- Add a keybinding to open noice errors with telescope
  --     require('which-key').register({
  --         n = {
  --           name = 'LSP/IDE Operations',
  --           e = { ':Telescope noice<cr>', 'Show messages history' },
  --         }
  --       },
  --       { prefix = '<leader>' }
  --     )
  --     --
  --   end
  -- },

}

local art = require('brpol.ascii_art')

return {
  {
    'nvimdev/dashboard-nvim',
    event = 'VimEnter',
    config = function()
      local dashLogo = {}
      for k, v in pairs(art.enterprise) do
        dashLogo[k] = v
      end
      for k, v in pairs(art.neovim) do
        dashLogo[k] = v
      end

      local config_time = require('configpulse').get_time()
      local config_time_string = string.format(
        'It has been %d days, %d hours, and %d minutes since you last alterned your Neovim configuration.',
        config_time.days, config_time.hours, config_time.minutes)

      require('dashboard').setup {
        theme = 'doom',
        shortcut_type = 'letter',
        config = {
          header = dashLogo,
          footer = { config_time_string }
        },
      }
    end,
    dependencies = {
      'nvim-tree/nvim-web-devicons',
      'mrquantumcodes/configpulse'
    }
  },

  {
    'jsongerber/thanks.nvim',
    opts = {
      plugin_manager = 'lazy',
    }
  },

  -- Imports vscode settings.json coc settings and nlsp and has its own .neoconf.json
  {
    'folke/neoconf.nvim',
    config = function()
      require('neoconf').setup()
    end,
  },
  {
    'folke/neodev.nvim',
    config = function()
      require('neodev').setup()
    end
  },

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

  -- AUtoclose
  {
    'm4xshen/autoclose.nvim',
    config = function()
      require('autoclose').setup()
    end
  },

  -- Easymotion
  {
    'smoka7/hop.nvim',
    version = '*',
    lazy = false,
    opts = {},
    config = function()
      local hop = require('hop')
      local directions = require('hop.hint').HintDirection
      local positions = require('hop.hint').HintPosition
      local wk = require('which-key')

      hop.setup({
        quit_key = '<SPC>',
        keys = 'asdfghjkl;qwertyuiopzxcvbnm',
        multi_windows = true,
      })

      local bindings = {
        ['<leader><leader>w'] = { function() hop.hint_words({ direction = directions.AFTER_CURSOR }) end, 'Easymotion w' },
        ['<leader>e'] = { function()
          hop.hint_words({
            direction = directions.AFTER_CURSOR,
            hint_position = positions
                .END
          })
        end, 'Easymotion e' },
        ['<leader><leader>b'] = { function() hop.hint_words({ direction = directions.BEFORE_CURSOR }) end, 'Easymotion b' },
        ['<leader><leader>j'] = { function() hop.hint_lines_skip_whitespace({ direction = directions.AFTER_CURSOR }) end, 'Easymotion j' },
        ['<leader><leader>k'] = { function() hop.hint_lines_skip_whitespace({ direction = directions.BEFORE_CURSOR }) end, 'Easymotion k' },
        ['<leader><leader>f'] = { function() hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = true }) end, 'Easymotion f' },
        ['<leader><leader>F'] = { function() hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = true }) end, 'Easymotion F' },
        ['<leader><leader>t'] = { function() hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = true, hint_offset = -1 }) end, 'Easymotion t' },
        ['<leader><leader>T'] = { function() hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = true, hint_offset = 1 }) end, 'Easymotion T' },
      }

      wk.register {
        bindings,
        { mode = 'n' }
      }

      for bind, fd in pairs(bindings) do
        local f = fd[1]
        vim.keymap.set('v', bind, f, { noremap = true })
      end

      -- Color configuration
      vim.cmd('hi HopNextKey guifg=White')
      vim.cmd('hi HopNextKey guibg=Red')
      vim.cmd('hi HopNextKey1 guifg=White')
      vim.cmd('hi HopNextKey1 guibg=Red')
      vim.cmd('hi HopNextKey2 guifg=White')
      vim.cmd('hi HopNextKey2 guibg=Red')
    end
  },

  -- Window picker
  {
    'ten3roberts/window-picker.nvim',
    config = function()
      require('window-picker').setup {
        -- Default keys to annotate, keys will be used in order. The default uses the
        -- most accessible keys from the home row and then top row.
        keys = 'alskdjfhgwoeiruty',
        -- Swap windows by holding shift + letter
        swap_shift = true,
        -- Windows containing filetype to exclude
        exclude = { qf = true, NvimTree = true, aerial = true },
        -- Flash the cursor line of the newly focused window for 300ms.
        -- Set to 0 or false to disable.
        flash_duration = 300,
      }

      require('which-key').register(
        {
          ['<leader>W'] = { ':WindowPick<cr>', 'Pick a window' },
        },
        {
          prefix = '<leader>',
        }
      )
    end
  },


  {
    'kylechui/nvim-surround',
    version = '*', -- Use for stability; omit to use `main` branch for the latest features
    event = 'VeryLazy',
    config = function()
      require('nvim-surround').setup({
        -- Configuration here, or leave empty to use defaults
      })
    end
  },

  -- Fuzzy finder (file finder etc), see "after" config directory for bindings,
  -- ctrl-p from vscode is equivalent and for non git repos there is <leader>ff
  {
    'nvim-telescope/telescope.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' }
  },
  {
    'danielfalk/smart-open.nvim',
    branch = '0.2.x',
    dependencies = {
      'nvim-telescope/telescope.nvim',
      'kkharji/sqlite.lua',
      -- Only required if using match_algorithm fzf
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
      -- Optional.  If installed, native fzy will be used when match_algorithm is fzy
      { 'nvim-telescope/telescope-fzy-native.nvim' },
    },
    config = function()
      local extensions = require('telescope').extensions

      vim.keymap.set('n', '<C-p>', function() extensions.smart_open.smart_open({ cwd_only = true }) end, {})

      -- Hack to make Ctrl-C work to close
      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('user-telescope-picker', { clear = true }),
        pattern = { 'TelescopePrompt' },
        callback = function(event)
          vim.keymap.set('i', '<C-c>', function()
            require('telescope.actions').close(event.buf)
          end, { noremap = true, silent = true, buffer = event.buf })
        end,
      })

      local telescopeConfig = require('telescope.config')
      local vimgrep_arguments = { unpack(telescopeConfig.values.vimgrep_arguments) }
      table.insert(vimgrep_arguments, '--hidden')
      -- I don't want to search in the `.git` directory.
      table.insert(vimgrep_arguments, '--glob')
      table.insert(vimgrep_arguments, '!**/.git/*')
      require('telescope').setup({
        defaults = {
          vimgrep_arguments = vimgrep_arguments,
        },
        pickers = {
          find_files = {
            -- `hidden = true` will still show the inside of `.git/` as it's not `.gitignore`d.
            find_command = { 'rg', '--files', '--hidden', '--glob', '!**/.git/*' },
          },
        },
        extensions = {
          smart_open = {
            show_scores = false,
            ignore_patterns = { '*.git/*' },
            -- Enable to use fzy, needs to be installed though
            match_algorithm = 'fzy',
            disable_devicons = false,
            -- open_buffer_indicators = {previous = "👀", others = "🙈"},
          },
        }
      })

      require('telescope').load_extension('smart_open')
    end,
  },
  {
    'nvim-telescope/telescope-ui-select.nvim',
    dependencies = { 'nvim-telescope/telescope.nvim' },
    config = function()
      require('telescope').setup {
        extensions = {
          ['ui-select'] = {
            require('telescope.themes').get_dropdown {
              -- even more opts
            }

            -- pseudo code / specification for writing custom displays, like the one
            -- for "codeactions"
            -- specific_opts = {
            --   [kind] = {
            --     make_indexed = function(items) -> indexed_items, width,
            --     make_displayer = function(widths) -> displayer
            --     make_display = function(displayer) -> function(e)
            --     make_ordinal = function(e) -> string
            --   },
            --   -- for example to disable the custom builtin "codeactions" display
            --      do the following
            --   codeactions = false,
            -- }
          }
        }
      }
      require('telescope').load_extension('ui-select')
    end
  },

  {
    'nvim-treesitter/nvim-treesitter', -- Better syntax highlighting etc
    build = function()
      require('nvim-treesitter.install').update({ with_sync = true })()
    end,
    config = function()
      require('nvim-treesitter.configs').setup({
        -- A list of parser names, or "all" https://github.com/nvim-treesitter/nvim-treesitter?tab=readme-ov-file#supported-languages
        ensure_installed = 'all',

        -- Install parsers synchronously (only applied to `ensure_installed`)
        sync_install = false,

        -- Automatically install missing parsers when entering buffer
        -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
        auto_install = true,

        highlight = {
          enable = true,

          -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
          -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
          -- Using this option may slow down your editor, and you may see some duplicate highlights.
          -- Instead of true it can also be a list of languages
          additional_vim_regex_highlighting = false,
        },

        incremental_selection = {
          enable = true,
          keymaps = {
            node_incremental = 'u',
            node_decremental = 'V',
          }
        }
      })

      -- https://github.com/RRethy/vim-illuminate?tab=readme-ov-file#highlight-groups
    end,
  },
  {
    'RRethy/vim-illuminate',
    dependencies = 'nvim-treesitter/nvim-treesitter',
    config = function()
      -- default configuration
      require('illuminate').configure({
        -- providers: provider used to get references in the buffer, ordered by priority
        providers = {
          'lsp',
          'treesitter',
          'regex',
        },
        -- delay: delay in milliseconds
        delay = 100,
        -- filetype_overrides: filetype specific overrides.
        -- The keys are strings to represent the filetype while the values are tables that
        -- supports the same keys passed to .configure except for filetypes_denylist and filetypes_allowlist
        filetype_overrides = {},
        -- filetypes_denylist: filetypes to not illuminate, this overrides filetypes_allowlist
        filetypes_denylist = {
          'dirbuf',
          'dirvish',
          'fugitive',
        },
        -- filetypes_allowlist: filetypes to illuminate, this is overridden by filetypes_denylist
        -- You must set filetypes_denylist = {} to override the defaults to allow filetypes_allowlist to take effect
        filetypes_allowlist = {},
        -- modes_denylist: modes to not illuminate, this overrides modes_allowlist
        -- See `:help mode()` for possible values
        modes_denylist = {},
        -- modes_allowlist: modes to illuminate, this is overridden by modes_denylist
        -- See `:help mode()` for possible values
        modes_allowlist = {},
        -- providers_regex_syntax_denylist: syntax to not illuminate, this overrides providers_regex_syntax_allowlist
        -- Only applies to the 'regex' provider
        -- Use :echom synIDattr(synIDtrans(synID(line('.'), col('.'), 1)), 'name')
        providers_regex_syntax_denylist = {},
        -- providers_regex_syntax_allowlist: syntax to illuminate, this is overridden by providers_regex_syntax_denylist
        -- Only applies to the 'regex' provider
        -- Use :echom synIDattr(synIDtrans(synID(line('.'), col('.'), 1)), 'name')
        providers_regex_syntax_allowlist = {},
        -- under_cursor: whether or not to illuminate under the cursor
        under_cursor = true,
        -- large_file_cutoff: number of lines at which to use large_file_config
        -- The `under_cursor` option is disabled when this cutoff is hit
        large_file_cutoff = nil,
        -- large_file_config: config to use for large files (based on large_file_cutoff).
        -- Supports the same keys passed to .configure
        -- If nil, vim-illuminate will be disabled for large files.
        large_file_overrides = nil,
        -- min_count_to_highlight: minimum number of matches required to perform highlighting
        min_count_to_highlight = 1,
        -- should_enable: a callback that overrides all other settings to
        -- enable/disable illumination. This will be called a lot so don't do
        -- anything expensive in it.
        should_enable = function(bufnr) return true end,
        -- case_insensitive_regex: sets regex case sensitivity
        case_insensitive_regex = false,
      })
    end
  },

  -- modern NERDTree
  {
    'nvim-tree/nvim-tree.lua',
    version = '*',
    lazy = false,
    dependencies = {
      'nvim-tree/nvim-web-devicons',
      {
        'JMarkin/nvim-tree.lua-float-preview',
        lazy = false,
        -- default
        opts = {
          -- Whether the float preview is enabled by default. When set to false, it has to be "toggled" on.
          toggled_on = true,
          -- wrap nvimtree commands
          wrap_nvimtree_commands = true,
          -- lines for scroll
          scroll_lines = 20,
          -- window config
          window = {
            style = 'minimal',
            relative = 'win',
            border = 'rounded',
            wrap = false,
          },
          mapping = {
            -- scroll down float buffer
            down = { '<C-d>' },
            -- scroll up float buffer
            up = { '<C-e>', '<C-u>' },
            -- enable/disable float windows
            toggle = { '<C-x>' },
          },
          -- hooks if return false preview doesn't shown
          hooks = {
            pre_open = function(path)
              -- if file > 5 MB or not text -> not preview
              local size = require('float-preview.utils').get_size(path)
              if type(size) ~= 'number' then
                return false
              end
              local is_text = require('float-preview.utils').is_text(path)
              return size < 5 and is_text
            end,
            post_open = function(bufnr)
              return true
            end,
          },
        },
      }
    },
    config = function()
      local function change_root_to_global_cwd()
        local api = require('nvim-tree.api')
        local global_cwd = vim.fn.getcwd(-1, -1)
        api.tree.change_root(global_cwd)
      end

      require('nvim-tree').setup({
        on_attach = function(bufnr)
          local floatPreview = require('float-preview')
          floatPreview.attach_nvimtree(bufnr)

          local function opts(desc)
            return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
          end

          local nvimTreeApi = require('nvim-tree.api')

          -- Run Default first
          nvimTreeApi.config.mappings.default_on_attach(bufnr)
          vim.keymap.set('n', '<C-c>', change_root_to_global_cwd, opts('Change Root To Global CWD'))
          vim.keymap.set('n', '?', nvimTreeApi.tree.toggle_help, opts('Help'))
          vim.keymap.set('n', 'v', nvimTreeApi.node.open.vertical, opts('Open: Vertical Split'))
          vim.keymap.set('n', '<CR>', nvimTreeApi.node.open.no_window_picker, opts('Open'))
          vim.keymap.set('n', 'o', nvimTreeApi.node.open.no_window_picker, opts('Open'))
          vim.keymap.set('n', 'O', nvimTreeApi.node.open.no_window_picker, opts('Open: Window Picker'))
        end
      })

      -- Allow for LSP refactors etc to work from the tree
      require('lsp-file-operations').setup()
    end,
  },
  {
    'antosha417/nvim-lsp-file-operations',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-tree.lua',
    },
    config = function()
      require('lsp-file-operations').setup()
    end,
  },

  -- Pretty status line
  {
    'nvim-lualine/lualine.nvim',
    dependencies = {
      'nvim-tree/nvim-web-devicons',
      'linrongbin16/lsp-progress.nvim',
      'Mofiqul/vscode.nvim',
      'folke/noice.nvim'
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
              if require('noice').api.statusline.mode.has() then
                return require('noice').api.statusline.mode.get()
              else
                return ''
              end
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

  {
    'folke/which-key.nvim', -- Helps remember keybindings
    event = 'VeryLazy',
    init = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300
    end,
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    }
  },

  {
    'numToStr/Comment.nvim',
    opts = {
      -- add any options here
    },
    lazy = false,
    config = function()
      require('Comment').setup()
    end
  },

  {
    'ziontee113/icon-picker.nvim',
    dependencies = {
      'stevearc/dressing.nvim',
      'folke/which-key.nvim', -- Helps remember keybindings
    },
    config = function()
      require('icon-picker').setup({ disable_legacy_commands = true })

      require('which-key').register({
        i = {
          name = 'Insert Stuff',
          e = { '<cmd>IconPickerNormal<cr>', 'Emoji Picker' },
          E = { '<cmd>IconPickerYank<cr>', 'Emoji Picker into register' }
        }
      }, { prefix = '<leader>' })
      -- TODO try to use which key for this like so: [C-i] = {}
      -- vim.keymap.set('i', '<C-i>', '<cmd>IconPickerInsert<cr>', { remap = false })
    end
  },

  -- Terminal that toggles like vscode
  {
    'akinsho/toggleterm.nvim',
    version = '*',
    config = function()
      local sessionNamePrefix = vim.fn.getcwd() .. '#nvim'
      -- TODO binding to cycle through these
      local terminal_type = 'horizontal'
      require('toggleterm').setup {
        size = function(term)
          if term.direction == 'horizontal' then
            return 20
          elseif term.direction == 'vertical' then
            return 50
          end
        end,
        open_mapping = [[<c-\>]],
        direction = terminal_type,
        on_create = function(term)
          vim.notify('Remember to prefix twice <C-a> C<C-a> to send to tmux in nvim if already running in tmux')
          term:send(' export HISTCONTROL=ignorespace', false)
          term:send(' tmux new-session -A -s ' .. sessionNamePrefix .. term.id, false)
          term:send(' export NVIM=' .. vim.v.servername)
        end,
        on_open = function(term)
          vim.cmd('startinsert')
        end,
        on_close = function(term)
          -- Cancel current command with interrupt then detach tmux
          -- term:send(' tmux detach', false)
        end,
        float_opts = {
          -- The border key is *almost* the same as 'nvim_open_win'
          -- see :h nvim_open_win for details on borders however
          -- the 'curved' border is a custom border type
          -- not natively supported but implemented in this plugin.
          -- border = 'single' | 'double' | 'shadow' | 'curved' | ... other options supported by win open
          border = 'double',
          -- like `size`, width, height, row, and col can be a number or function which is passed the current terminal
          winblend = 20,
          title_pos = 'left',
        },
      }

      local wk = require('which-key')
      wk.register({
        ['<C-\\>'] = { ':ToggleTerm<cr>', 'Toggle Terminal, takes a prefix for term #' },
      }, {})
      wk.register(
        {
          t = {
            name = 'Terminals',
            t = { ':ToggleTerm<cr>', 'Toggle Terminal' },
            s = { ':TermSelect<cr>', 'Select from list of open terminals' },
            n = {
              function()
                local term = require('toggleterm.terminal').get_last_focused()
                -- check a terminal exists
                if not term then
                  vim.notify('No terminal to rename')
                  return
                end

                local name = vim.fn.input('Set name of a terminal: ')
                vim.cmd('ToggleTermSetName ' .. name)
              end,
              'Set terminal name'
            },
            e = { ':ToggleTermSendCurrentLine<cr>', 'Execute current line in terminal' },
          }
        },
        { prefix = '<leader>' }
      )

      wk.register(
        {
          t = {
            name = 'Terminals',
            e = { ':ToggleTermSendVisualSelection<cr>', 'Execute current selection in terminal' },
          },
        },
        {
          prefix = '<leader>',
          mode = 'v',
        }
      )

      -- Return to normal mode from terminal mode to leave terminal open etc
      vim.keymap.set('t', '<C-/>', function() vim.cmd('stopinsert') end, { noremap = true })
    end
  },
  {
    'willothy/flatten.nvim',
    dependencies = { 'akinsho/toggleterm.nvim' },
    lazy = false,
    priority = 1001,
    config = function()
      ---@type Terminal?
      local saved_terminal

      require('flatten').setup {
        window = {
          open = 'alternate',
        },
        callbacks = {
          should_block = function(argv)
            -- Note that argv contains all the parts of the CLI command, including
            -- Neovim's path, commands, options and files.
            -- See: :help v:argv

            -- In this case, we would block if we find the `-b` flag
            -- This allows you to use `nvim -b file1` instead of
            -- `nvim --cmd 'let g:flatten_wait=1' file1`
            return vim.tbl_contains(argv, '-b')

            -- Alternatively, we can block if we find the diff-mode option
            -- return vim.tbl_contains(argv, "-d")
          end,
          pre_open = function()
            local term = require('toggleterm.terminal')
            local termid = term.get_focused_id()
            saved_terminal = term.get(termid)
          end,
          post_open = function(bufnr, winnr, ft, is_blocking)
            if is_blocking and saved_terminal then
              -- Hide the terminal while it's blocking
              saved_terminal:close()
            else
              -- If it's a normal file, just switch to its window
              vim.api.nvim_set_current_win(winnr)
            end

            -- If the file is a git commit, create one-shot autocmd to delete its buffer on write
            -- If you just want the toggleable terminal integration, ignore this bit
            if ft == 'gitcommit' or ft == 'gitrebase' then
              vim.api.nvim_create_autocmd('BufWritePost', {
                buffer = bufnr,
                once = true,
                callback = vim.schedule_wrap(function()
                  vim.api.nvim_buf_delete(bufnr, {})
                end),
              })
            end
          end,
          block_end = function()
            -- After blocking ends (for a git commit, etc), reopen the terminal
            vim.schedule(function()
              if saved_terminal then
                saved_terminal:open()
                saved_terminal = nil
              end
            end)
          end,
        },
      }
    end,
  },

  -- Sessions and workspaces
  {
    'natecraddock/sessions.nvim',
    lazy = false,
    config = function()
      local sessions = require('sessions')

      local dir = vim.fn.stdpath('data') .. '/sessions'
      vim.fn.mkdir(dir, 'p')

      sessions.setup {
        session_filepath = dir,
        absolute = true,
      }

      sessions.start_autosave()
    end
  },
  {
    'natecraddock/workspaces.nvim',
    dependencies = {
      'natecraddock/sessions.nvim',
      'nvim-telescope/telescope.nvim',
    },

    build = function()
      local workspaces = require('workspaces')

      local project_directories = (os.getenv('PROJECT_DIRS') or '')
      for dir in string.gmatch(project_directories, '[^:]+') do
        workspaces.add_dir(dir)
      end

      workspaces.add(vim.fn.expand('$HOME/rcfiles/.config/nvim'), 'Neovim Configuration')
      workspaces.add(vim.fn.expand('$HOME/rcfiles/'), 'rcfiles')
    end,

    config = function()
      local workspaces = require('workspaces')
      workspaces.sync_dirs()

      require('which-key').register({
          w = {
            name = 'Workspaces and sessons',
            w = { ':Telescope workspaces<cr>', 'Open Workspaces (fuzzy)' },
            a = { ':WorkspacesAdd<cr>', 'Add current directory to workspaces' },
            l = { ':SessionsLoad<cr>', 'Load default session for workspace' },
          }
        },
        { prefix = '<leader>' }
      )

      workspaces.setup({
        hooks = {
          open_pre = {
            -- Stop current session and delete all buffers
            'SessionsStop',
            'silent %bdelete!'
          },
          open = function()
            local loaded = require('sessions').load(nil, { silent = true })
            if not loaded then
              require('sessions').start_autosave()
            end
          end,
        }
      })
    end
  },


  -- LSP stuff
  --- Uncomment the two plugins below if you want to manage the language servers from neovim
  { 'williamboman/mason.nvim' },
  { 'williamboman/mason-lspconfig.nvim' },
  { 'VonHeikemen/lsp-zero.nvim',        branch = 'v3.x' },
  { 'neovim/nvim-lspconfig' },
  { 'hrsh7th/cmp-nvim-lsp' },
  { 'hrsh7th/nvim-cmp' },
  { 'hrsh7th/cmp-buffer' },
  { 'hrsh7th/cmp-path' },
  {
    'L3MON4D3/LuaSnip',
    dependencies = { 'rafamadriz/friendly-snippets', 'saadparwaiz1/cmp_luasnip', 'benfowler/telescope-luasnip.nvim' },
    config = function()
      require('luasnip.loaders.from_vscode').lazy_load()
      require('telescope').load_extension('luasnip')
    end
  },
  {
    'mhanberg/output-panel.nvim',
    event = 'VeryLazy',
    config = function()
      require('output_panel').setup()
    end
  },

  -- Refactor stuff when LSP doesnt work
  {
    'ThePrimeagen/refactoring.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
      'nvim-telescope/telescope.nvim',
    },
    config = function()
      require('refactoring').setup()
      require('telescope').load_extension('refactoring')

      local wk = require('which-key')
      wk.register({
          r = {
            name = 'Refactors',
            e = { ':Refactor extract ', 'Extract' },
            f = { ':Refactor extract_to_file ', 'Extract to file' },
            v = { ':Refactor extract_var ', 'Extract variable' },
          }
        },
        {
          mode = 'x',
          prefix = '<leader>',
        })

      local sharedBindings = {
        r = {
          name = 'Refactors',
          r = { function() require('refactoring').select_refactor() end, 'Select refactor' },
          i = { ':Refactor inline_var', 'Inline variable' },
        }
      }
      wk.register(sharedBindings,
        {
          mode = 'x',
          prefix = '<leader>',
        })
      wk.register(sharedBindings,
        {
          mode = 'n',
          prefix = '<leader>',
        })

      wk.register({
          r = {
            name = 'Refactors',
            I = { ':Refactor inline_func', 'Inline function' },
            b = { ':Refactor extract_block', 'Extract block' },
            B = { ':Refactor extract_block_to_file', 'Extract block to file' },
          }
        },
        {
          mode = 'n',
          prefix = '<leader>',
        })
    end,
  },

  -- Git stuff
  {
    'lewis6991/gitsigns.nvim',
    config = function()
      local gs = require('gitsigns')
      gs.setup {
        current_line_blame = true,
        current_line_blame_opts = {
          virt_text_pos = 'right_align',
          delay = 50,
        },
        on_attach = function(bufnr)
          local wk = require('which-key')

          wk.register(
            {
              g = {
                n = { gs.next_hunk, 'Next git hunk' },
                N = { gs.prev_hunk, 'Prev git hunk' },
                R = { gs.reset_buffer, 'Reset buffer' },
                h = {
                  name = 'hunk operations',
                  p = { gs.preview_hunk, 'Preview hunk' },
                  s = { function() gs.stage_hunk { vim.fn.line('.'), vim.fn.line('v') } end, 'Stage hunk' },
                  d = { gs.diffthis, 'Diff against index' },
                  D = { function() gs.diffthis('~') end, 'Diff against last commit' },
                  r = { function() gs.reset_hunk { vim.fn.line('.'), vim.fn.line('v') } end, 'Reset hunk' },
                },
              }
            },
            { prefix = '<leader>' }
          )
          wk.register(
            {
              g = {
                n = { gs.next_hunk, 'Next git hunk' },
                N = { gs.prev_hunk, 'Prev git hunk' },
                R = { gs.reset_buffer, 'Reset buffer' },
                h = {
                  name = 'hunk operations',
                  p = { gs.preview_hunk, 'Preview hunk' },
                  s = { function() gs.stage_hunk { vim.fn.line('.'), vim.fn.line('v') } end, 'Stage hunk' },
                  d = { gs.diffthis, 'Diff against index' },
                  D = { function() gs.diffthis('~') end, 'Diff against last commit' },
                  r = { function() gs.reset_hunk { vim.fn.line('.'), vim.fn.line('v') } end, 'Reset hunk' },
                },
              }
            },
            { mode = 'x', prefix = '<leader>' }
          )
        end
      }
    end
  },
  {
    'sindrets/diffview.nvim',
    config = function()
      require('diffview').setup()
      require('which-key').register({
          g = {
            name = 'Git',
            d = { ':DiffviewOpen<cr>', 'Open Diffview' },
            D = { ':DiffviewClose<cr>', 'Close Diffview' },
            R = { ':DiffviewRefresh<cr>', 'Refresh Diffview' },
            h = { ':DiffviewFileHistory<cr>', 'File History' },
          }
        },
        { prefix = '<leader>' }
      )

      require('which-key').register(
        {
          g = {
            name = 'Git',
            h = { ":'<,'>DiffviewFileHistory<cr>", 'File History (selection)' },
          }
        },
        { prefix = '<leader>', mode = 'v' }
      )
    end
  },
  {
    'wintermute-cell/gitignore.nvim',
    dependencies = { 'nvim-telescope/telescope.nvim' },
    config = function()
      require('gitignore')
    end,
  },

  -- Buffer line aka tabs
  {
    'akinsho/bufferline.nvim',
    version = '*',
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
    'LukasPietzschmann/telescope-tabs',
    event = 'VeryLazy',
    config = function()
      local tt = require('telescope-tabs')

      tt.setup()

      require('which-key').register({
          b = {
            name = 'Buffers/Tabs',
            t = { tt.list_tabs, 'Switch tabs (as in workspaces)' },
            T = { tt.go_to_previous, 'Go to previous tab' },
          }
        },
        { prefix = '<leader>' }
      )
    end
  },


  -- Formatting
  {
    'stevearc/conform.nvim',
    opts = {},
    dependencies = { 'folke/which-key.nvim' },
    config = function()
      require('conform').setup({
        formatters_by_ft = {
          python = { 'black', 'isort' },
          javascript = { { 'prettierd', 'prettier' } },
        },
        format_on_save = {
          timeout_ms = 5000,
          lsp_fallback = true,
        },
      })

      require('which-key').register({
          v = {
            name = 'LSP/IDE Operations',
            f = { require('conform').format, 'Format File' },
          }
        },
        { prefix = '<leader>' }
      )
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
      require('notify').setup({
        -- render = 'compact',
        timeout = 4000,
        fps = 10, -- default is 30
        stages = 'static',
      })
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
      require('which-key').register({
          n = {
            name = 'LSP/IDE Operations',
            e = { ':Telescope noice<cr>', 'Show messages history' },
          }
        },
        { prefix = '<leader>' }
      )
      --
    end
  },

  -- Github copilot
  {
    'github/copilot.vim',
    build = function()
      vim.cmd('Copilot setup')
    end,
    config = function()
      CopilotEnabled = true
      local function toggle_copilot()
        CopilotEnabled = not CopilotEnabled
        if CopilotEnabled then
          vim.cmd('Copilot enable')
          vim.notify('Copilot enabled')
        else
          vim.cmd('Copilot disable')
          vim.notify('Copilot disabled')
        end
      end

      require('which-key').register({
          c = {
            name = 'Github Copilot Operations',
            T = { toggle_copilot, 'Toggle Copilot' },
            l = { ':vert rightb Copilot panel<cr>', 'List Suggestions' },
            s = { ':<Plug>(copilot-suggest)<cr>', 'Suggest' },
            d = { ':<Plug>(copilot-dismiss)<cr>', 'Dismiss' },
            n = { ':<Plug>(copilot-next)<cr>', 'Next Suggestion' },
            p = { ':<Plug>(copilot-previous)<cr>', 'Previous Suggestion' },
          },
        },
        { prefix = '<leader>' }
      )

      -- Add keybinding for insert mode for suggestion panel
      require('which-key').register(
        {
          ['<C-l>'] = { function() vim.cmd('vert rightb Copilot panel') end, 'List suggestions' },
          ['<C-]>'] = { ':<Plug>(copilot-next)<cr>', 'Next Suggestion' },
          ['<C-[>'] = { ':<Plug>(copilot-previous)<cr>', 'Previous Suggestion' },
        },
        { mode = 'i' }
      )
    end
  },
  {
    'CopilotC-Nvim/CopilotChat.nvim',
    dependencies = {
      { 'github/copilot.vim' },    -- or github/copilot.vim
      { 'nvim-lua/plenary.nvim' }, -- for curl, log wrapper
    },
    opts = {
      window = {
        layout = 'float'
      }
    },
    -- TODO copy paste this and put it in it's own file: https://github.com/jellydn/lazy-nvim-ide/blob/main/lua/plugins/extras/copilot-chat-v2.lua
    config = function()
      local chat = require('CopilotChat')
      local select = require('CopilotChat.select')

      chat.setup()

      vim.api.nvim_create_user_command('CopilotChatInline', function(args)
        chat.ask(args.args, {
          selection = select.visual,
          window = {
            layout = 'float',
            relative = 'cursor',
            width = 1,
            height = 0.2,
            row = 1,
          },
        })
      end, { nargs = '*', range = true })

      local wk = require('which-key')
      wk.register({
          c = {
            name = 'Github Copilot Operations',
            c = { ':CopilotChatInline<cr>', 'CopilotChat - Chat with current buffer' },
            e = { ':CopilotChatExplain<cr>', 'CopilotChat - Explain code' },
            gt = { ':CopilotChatTests<cr>', 'CopilotChat - Generate tests' },
            f = { ':CopilotChatFixDiagnostic<cr>', 'CopilotChat - Fix diagnostic', },
            R = { ':CopilotChatReset<cr>', 'CopilotChat - Reset chat history and clear buffer', }
          }
        },
        {
          mode = 'n',
          prefix = '<leader>',
          silent = true,
          noremap = true,
          nowait = false,
        })
    end
  },

  -- Individual language tools
  -- Elixir
  {
    'elixir-tools/elixir-tools.nvim',
    version = '*',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      local elixir = require('elixir')
      local elixirls = require('elixir.elixirls')
      local wk = require('which-key')

      elixir.setup {
        nextls = {
          -- cmd = vim.fn.expand('$HOME/.local/share/nvim/mason/bin/nextls')
        },

        credo = {
          version = '0.3.0',
        },

        elixirls = {
          cmd = vim.fn.expand('$HOME/.local/share/nvim/mason/bin/elixir-ls'),
          settings = elixirls.settings {
            fetchDeps = true,
            enableTestLenses = true,
            suggestSpecs = true,
            dialyzerEnabled = true,
            incrementalDialyzer = true,
          },
          on_attach = function()
            wk.register({
                E = {
                  name = 'Elixir Code Actions',
                  f = { ':ElixirFromPipe<cr>', 'Convert to standard function from pipe' },
                  p = { ':ElixirToPipe<cr>', 'Convert to pipe from standard function' },
                  m = { ':ElixirExpandMacro<cr>', 'Expand Macro' },
                }
              },
              { prefix = '<leader>' })
          end
        }
      }
    end,
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
  },

  -- Firenvim, use vim in chrome, firefox, and other web browsers
  {
    'glacambre/firenvim',
    priority = 1000,
    -- Explanation: https://github.com/folke/lazy.nvim/discussions/463#discussioncomment-4819297
    lazy = not vim.g.started_by_firenvim,
    build = function()
      require('lazy').load({ plugins = 'firenvim', wait = true })
      vim.fn['firenvim#install'](0)
    end,
    config = function()
      -- Manually trigger with ctrl+e (cmd on mac)
      vim.g.firenvim_config.localSettings = {
        ['.*'] = { takeover = 'never', },
      }
      vim.api.nvim_set_keymap('n', '<C-c><C-c>', '<Cmd>call firenvim#focus_page()<CR>', {})
    end
  }
}

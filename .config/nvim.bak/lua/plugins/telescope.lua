return {
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
      {
        'nvim-telescope/telescope-live-grep-args.nvim',
        -- This will not install any breaking changes.
        -- For major updates, this must be adjusted manually.
        version = '^1.0.0',
      },
    },
    config = function()
      local extensions = require('telescope').extensions

      vim.keymap.set('n', '<C-p>',
        function() extensions.smart_open.smart_open({ cwd_only = true, follow_symlinks = true }) end, {})

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
      -- Can be used to rg with arguments (so advanced regex, -t, --no-ignore, etc), just put the query in quotes.
      require('telescope').load_extension('live_grep_args')
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
    'LukasPietzschmann/telescope-tabs',
    event = 'VeryLazy',
    config = function()
      require('telescope').load_extension('telescope-tabs')
      local tt = require('telescope-tabs')

      tt.setup()

      require('which-key').add({
        {
          '<leader>b', group = 'Buffers/Tabs', },
        { '<leader>bt', tt.list_tabs,      desc = 'Switch tabs (as in workspaces)' },
        { '<leader>bT', tt.go_to_previous, desc = 'Go to previous tab' }
      })
    end
  },
}

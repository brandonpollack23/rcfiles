return {
  {
    'jsongerber/thanks.nvim',
    opts = {
      plugin_manager = 'lazy',
    }
  },

  {
    'sontungexpt/url-open',
    event = 'VeryLazy',
    cmd = 'URLOpenUnderCursor',
    config = function()
      local status_ok, url_open = pcall(require, 'url-open')
      if not status_ok then
        return
      end
      url_open.setup({})

      require('which-key').register({
        gx = { '<cmd>URLOpenUnderCursor<cr>', 'Open URL under cursor' },
      })
    end,
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

  -- Formatting
  {
    'stevearc/conform.nvim',
    opts = {},
    dependencies = {
      'folke/which-key.nvim',
      'lewis6991/gitsigns.nvim',
    },
    config = function()
      require('conform').setup({
        formatters_by_ft = {
          python = { 'black', 'isort' },
          javascript = { 'prettierd', 'prettier' },
          javascriptreact = { 'prettierd', 'prettier' },
          typescript = { 'prettierd', 'prettier' },
          typescriptreact = { 'prettierd', 'prettier' },
          go = { 'gofumpt' },
          cs = { 'csharpier' },
        },
        default_format_opts = {
          lsp_format = 'fallback',
        },
        format_on_save = {
          timeout_ms = 5000,
          lsp_fallback = true,
        },
      })

      -- Only format diffs on save to prevent noisy git history:
      local function format_modified(timeout_ms)
        local uv = vim.uv or vim.loop
        local start = uv.hrtime() / 1e6

        local hunks = require('gitsigns').get_hunks()
        local format = require('conform').format

        if hunks == nil or #hunks == 0 then
          vim.notify('No hunks to format', vim.log.levels.INFO)
          format()
          return
        end

        vim.notify('Formatting ' .. #hunks .. ' hunks', vim.log.levels.INFO)
        for i = #hunks, 1, -1 do
          local remaining = timeout_ms - (uv.hrtime() / 1e6 - start)
          if remaining < 0 then
            vim.notify('Timed out formatting diffs', vim.log.levels.ERROR)
            return
          end

          local hunk = hunks[i]
          if hunk ~= nil and hunk.type ~= 'delete' then
            local start = hunk.added.start
            local last = start + hunk.added.count
            -- nvim_buf_get_lines uses zero-based indexing -> subtract from last
            local last_hunk_line = vim.api.nvim_buf_get_lines(0, last - 2, last - 1, true)[1]
            local range = { start = { start, 0 }, ['end'] = { last - 1, last_hunk_line:len() } }
            format({ range = range })
          end
        end
      end
      -- Disable format on save, do it manually with <leader>vf until it is better
      -- vim.api.nvim_create_autocmd('BufWritePre', {
      --   pattern = '*',
      --   callback = function(args)
      --     vim.notify('Formatting diffs with conform and custom fn', vim.log.levels.INFO)
      --     format_modified(5000)
      --   end,
      -- })

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
      if not vim.g.started_by_firenvim then
        return
      end

      vim.g.firenvim_config = {
        globalSettings = {
          alt = 'all',
        },
        localSettings = {
          ['.*'] = {
            cmdline  = 'neovim',
            content  = 'text',
            priority = 0,
            selector = 'textarea',
            takeover = 'never',
          },
        }
      }
      vim.api.nvim_set_keymap('n', '<C-c><C-c>', '<Cmd>call firenvim#focus_page()<CR>', {})
    end,
  },

  -- Preview Markdown files
  {
    'toppair/peek.nvim',
    event = { 'VeryLazy' },
    build = 'deno task --quiet build:fast',
    config = function()
      require('peek').setup()
      vim.api.nvim_create_user_command('MarkdownOpen', require('peek').open, {})
      vim.api.nvim_create_user_command('MarkdownClose', require('peek').close, {})
    end,
  },

  {
    url = 'https://git.sr.ht/~ashie/licenses.nvim',
    config = function()
      require('licenses').setup({
        copyright_holder = 'Brandon Pollack',
        email = 'brandonpollack23@gmail.com',
        license = 'MIT'
      })
    end,
  },
}

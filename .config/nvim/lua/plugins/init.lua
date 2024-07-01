return {
  {
    'stevearc/profile.nvim',
    config = function()
      local should_profile = os.getenv('NVIM_PROFILE')
      if should_profile then
        require('profile').instrument_autocmds()
        if should_profile:lower():match('^start') then
          require('profile').start('*')
        else
          require('profile').instrument('*')
        end
      end

      local function toggle_profile()
        local prof = require('profile')
        if prof.is_recording() then
          prof.stop()
          vim.ui.input({ prompt = 'Save profile to:', completion = 'file', default = 'profile.json' }, function(filename)
            if filename then
              prof.export(filename)
              vim.notify(string.format('Wrote %s', filename))
            end
          end)
        else
          prof.start('*')
        end
      end
      vim.keymap.set('', '<f1>', toggle_profile)
    end
  },
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
    url = 'https://git.sr.ht/~reggie/licenses.nvim',
    config = function()
      require('licenses').setup({
        copyright_holder = 'Brandon Pollack',
        email = 'brandonpollack23@gmail.com',
        license = 'MIT'
      })
    end,
  },

  {
    'vhyrro/luarocks.nvim',
    priority = 1001,
    opts = {
      rocks = { 'magick' },
    },
  }
}

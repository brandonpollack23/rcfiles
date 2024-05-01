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
      -- Manually trigger with ctrl+e (cmd on mac)
      vim.g.firenvim_config.localSettings = {
        ['.*'] = { takeover = 'never', },
      }
      vim.api.nvim_set_keymap('n', '<C-c><C-c>', '<Cmd>call firenvim#focus_page()<CR>', {})
    end
  }
}

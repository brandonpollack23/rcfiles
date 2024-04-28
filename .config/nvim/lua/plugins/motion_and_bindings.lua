return {
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
        ['<leader><leader>w'] = { function()
          hop.hint_words({
            direction = directions
                .AFTER_CURSOR
          })
        end, 'Easymotion w' },
        ['<leader>e'] = { function()
          hop.hint_words({
            direction = directions.AFTER_CURSOR,
            hint_position = positions
                .END
          })
        end, 'Easymotion e' },
        ['<leader><leader>b'] = { function()
          hop.hint_words({
            direction = directions
                .BEFORE_CURSOR
          })
        end, 'Easymotion b' },
        ['<leader><leader>j'] = { function()
          hop.hint_lines_skip_whitespace({
            direction =
                directions.AFTER_CURSOR
          })
        end, 'Easymotion j' },
        ['<leader><leader>k'] = { function()
          hop.hint_lines_skip_whitespace({
            direction =
                directions.BEFORE_CURSOR
          })
        end, 'Easymotion k' },
        ['<leader><leader>f'] = { function()
          hop.hint_char1({
            direction = directions
                .AFTER_CURSOR,
            current_line_only = true
          })
        end, 'Easymotion f' },
        ['<leader><leader>F'] = { function()
          hop.hint_char1({
            direction = directions
                .BEFORE_CURSOR,
            current_line_only = true
          })
        end, 'Easymotion F' },
        ['<leader><leader>t'] = { function()
          hop.hint_char1({
            direction = directions
                .AFTER_CURSOR,
            current_line_only = true,
            hint_offset = -1
          })
        end, 'Easymotion t' },
        ['<leader><leader>T'] = { function()
          hop.hint_char1({
            direction = directions
                .BEFORE_CURSOR,
            current_line_only = true,
            hint_offset = 1
          })
        end, 'Easymotion T' },
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
}

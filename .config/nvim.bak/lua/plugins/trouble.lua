return {
  {
    'folke/trouble.nvim',
    dependencies = { 'nvim-telescope/telescope.nvim' },
    keys = {
      {
        '<leader>x',
        desc = 'Trouble',
      },
      {
        '<leader>xX',
        '<cmd>Trouble diagnostics toggle<cr>',
        desc = 'Diagnostics (Trouble)',
      },
      {
        '<leader>xx',
        '<cmd>Trouble diagnostics toggle filter.buf=0<cr>',
        desc = 'Buffer Diagnostics (Trouble)',
      },
      {
        '<leader>xs',
        '<cmd>Trouble symbols toggle focus=true<cr>',
        desc = 'Symbols (Trouble)',
      },
      {
        '<leader>xl',
        '<cmd>Trouble lsp toggle focus=false win.position=right<cr>',
        desc = 'LSP Definitions / references / ... (Trouble)',
      },
      {
        '<leader>xL',
        '<cmd>Trouble loclist toggle<cr>',
        desc = 'Location List (Trouble)',
      },
      {
        '<leader>xc',
        '<cmd>Trouble lsp_command toggle<cr>',
        desc = 'Trouble LSP Commands (Trouble)',
      },
      {
        '<leader>xq',
        '<cmd>Trouble qflist toggle<cr>',
        desc = 'Quickfix List (Trouble)',
      },
      {
        '<leader>xQ',
        '<cmd>Trouble qflist toggle<cr>',
        desc = 'Quickfix List qflist (Trouble)',
      }
    },
    opts = {
      focus = true,
    }, -- for default options, refer to the configuration section for custom setup.
    config = function()
      require('trouble').setup({
        modes = {
          symbols = {
            win = {
              size = .3,
            }
          },
          lsp = {
            win = {
              size = .3,
            }
          }
        }
      })

      local open_with_trouble = require('trouble.sources.telescope').open

      -- Use this to add more results without clearing the trouble list
      local add_to_trouble = require('trouble.sources.telescope').add

      local telescope = require('telescope')

      telescope.setup({
        defaults = {
          mappings = {
            i = {
              ['<c-t>'] = open_with_trouble,
              ['c-a'] = add_to_trouble
            },
            n = {
              ['<c-t>'] = open_with_trouble,
              ['c-a'] = add_to_trouble
            },
          },
        },
      })
    end
  }
}

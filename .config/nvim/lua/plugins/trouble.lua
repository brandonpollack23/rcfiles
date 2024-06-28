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
        '<leader>xx',
        '<cmd>Trouble diagnostics toggle<cr>',
        desc = 'Diagnostics (Trouble)',
      },
      {
        '<leader>xX',
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
        '<cmd>Trouble quickfix toggle<cr>',
        desc = 'Quickfix List (Trouble)',
      },
      {
        '<leader>xq',
        '<cmd>Trouble telescope toggle<cr>', -- Used for things added to 'quickfix' from telescope (it isnt quickfix anymore its just for telescope results) (telescope instead of quickfix)
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
      require('trouble').setup()

      local open_with_trouble = require('trouble.sources.telescope').open

      -- Use this to add more results without clearing the trouble list
      local add_to_trouble = require('trouble.sources.telescope').add

      local telescope = require('telescope')

      telescope.setup({
        defaults = {
          mappings = {
            i = { ['<c-t>'] = open_with_trouble },
            n = { ['<c-t>'] = open_with_trouble },
          },
        },
      })
    end
  }
}

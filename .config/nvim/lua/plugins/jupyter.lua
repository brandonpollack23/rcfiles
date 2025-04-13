return {
  {
    'benlubas/molten-nvim',
    version = '^1.0.0', -- use version <2.0.0 to avoid breaking changes
    dependencies = { '3rd/image.nvim' },
    build = ':UpdateRemotePlugins',
    init = function()
      -- these are examples, not defaults. Please see the readme
      vim.g.molten_image_provider = 'image.nvim'
      vim.g.molten_output_win_max_height = 20

      local wk = require('which-key')
      wk.add({
        { '<space>',  group = 'REPL/Jupyter' },
        { '<space>i', ':MoltenInit<CR>', desc = 'Initialize jupyter for buffer' },
        { '<space>D', ':MoltenDeinit<CR>', desc = 'Deinit jupyter for buffer' },
        { '<space>I', ':MoltenInfo<CR>', desc = 'Show info jupyter state' },
        { '<space>n', ':MoltenNext<CR>', desc = 'Next cell' },
        { '<space>p', ':MoltenPrev<CR>', desc = 'Prev cell' },
        { '<space>x', ':MoltenReevaluateCell<CR>', desc = '(Re)Evaluate Cell' },
        { '<space>h', ':MoltenHideOutput<CR>', desc = 'Hide output window' },
        { '<space>H', ':MoltenShow<CR>', desc = 'Show output window' },
        { '<space>!', ':MoltenInterrupt<CR>', desc = 'Interrupt hanging execution' },
      })
    end,
  },
}

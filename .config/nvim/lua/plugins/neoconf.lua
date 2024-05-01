return {
  -- Imports vscode settings.json coc settings and nlsp and has its own .neoconf.json
  {
    'folke/neoconf.nvim',
    config = function()
      require('neoconf').setup()
    end,
  },
  {
    'folke/neodev.nvim',
    dependencies = { 'rcarriga/nvim-dap-ui', },
    config = function()
      require('neodev').setup {
        library = {
          enabled = true,
          runtime = true,
          types = true,
          plugins = { 'nvim-dap-ui' },
        },
      }
    end
  },
}

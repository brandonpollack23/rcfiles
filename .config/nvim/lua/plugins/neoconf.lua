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
    config = function()
      require('neodev').setup()
    end
  },
}

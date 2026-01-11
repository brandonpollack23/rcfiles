local art = require('brpol.ascii_art')

return {
  {
    'nvimdev/dashboard-nvim',
    config = function()
      local dashLogo = {}
      for k, v in pairs(art.enterprise) do
        dashLogo[k] = v
      end
      for k, v in pairs(art.neovim) do
        dashLogo[k] = v
      end

      local config_time = require('configpulse').get_time()
      local config_time_string = string.format(
        'It has been %d days, %d hours, and %d minutes since you last alterned your Neovim configuration.',
        config_time.days, config_time.hours, config_time.minutes)

      require('dashboard').setup {
        theme = 'doom',
        shortcut_type = 'letter',
        config = {
          header = dashLogo,
          footer = { config_time_string }
        },
      }
    end,
    dependencies = {
      'nvim-tree/nvim-web-devicons',
      'mrquantumcodes/configpulse'
    }
  },
}

return {
  -- Project local settings for debuggers etc.
  -- Imports vscode settings.json coc settings and nlsp and has its own .neoconf.json
  {
    'folke/neoconf.nvim',
    priority = 52, -- load before other plugins that use lspconfig
    config = function()
      require('neoconf').setup()
    end,
  },

	{
		'folke/lazydev.nvim',
		ft = 'lua', -- only load on lua files
		opts = {
			library = {
				-- See the configuration section for more details
				-- Load luvit types when the `vim.uv` word is found
				{ path = 'luvit-meta/library', words = { 'vim%.uv' } },
			},
		},
	},
	{ 'Bilal2453/luvit-meta', lazy = true }, -- optional `vim.uv` typings
	{                                       -- optional completion source for require statements and module annotations
		'hrsh7th/nvim-cmp',
		opts = function(_, opts)
			opts.sources = opts.sources or {}
			table.insert(opts.sources, {
				name = 'lazydev',
				group_index = 0, -- set group index to 0 to skip loading LuaLS completions
			})
		end,
	},

	-- exrc is secure in neovim, no need for a plugin, just enable it.
}

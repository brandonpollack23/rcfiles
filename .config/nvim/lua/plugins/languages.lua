return {
  -- Elixir
  {
    'elixir-tools/elixir-tools.nvim',
    version = '*',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      local elixir = require('elixir')
      local elixirls = require('elixir.elixirls')
      local wk = require('which-key')

      elixir.setup {
        nextls = {
          -- cmd = vim.fn.expand('$HOME/.local/share/nvim/mason/bin/nextls')
        },

        credo = {
          version = '0.3.0',
        },

        elixirls = {
          cmd = vim.fn.expand('$HOME/.local/share/nvim/mason/bin/elixir-ls'),
          settings = elixirls.settings {
            fetchDeps = true,
            enableTestLenses = true,
            suggestSpecs = true,
            dialyzerEnabled = true,
            incrementalDialyzer = true,
          },
          on_attach = function()
            wk.register({
                e = {
                  name = 'Elixir Code Actions',
                  f = { ':ElixirFromPipe<cr>', 'Convert to standard function from pipe' },
                  p = { ':ElixirToPipe<cr>', 'Convert to pipe from standard function' },
                  m = { ':ElixirExpandMacro<cr>', 'Expand Macro' },
                }
              },
              { prefix = '<leader>' })
          end
        }
      }
    end,
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
  },

  -- golang
  {
    'ray-x/go.nvim',
    dependencies = { -- optional packages
      'ray-x/guihua.lua',
      'neovim/nvim-lspconfig',
      'nvim-treesitter/nvim-treesitter',
    },
    config = function()
      require('go').setup()
    end,
    event = { 'CmdlineEnter' },
    ft = { 'go', 'gomod' },
    build = ':lua require("go.install").update_all_sync()' -- if you need to install/update all binaries
  },
}

-- Pattern for language specific stuff
--
-- vim.api.nvim_create_autocmd("BufEnter", {
--   pattern = "*.go",
--   callback = add_go_keybindings,
-- })
--
-- vim.api.nvim_create_autocmd("BufLeave", {
--   pattern = "*.go",
--   callback = remove_go_keybindings,
-- })
--
-- function add_go_keybindings()
-- wk.register({ -- etc
-- end
--
-- function remove_go_keybindings()
-- wk.register({ -- etc
-- KEY = "which_key_ignore"

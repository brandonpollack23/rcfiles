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

-- I use <leader>h for language specific stuff.

return {
  -- Elixir
  {
    'elixir-tools/elixir-tools.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'folke/which-key.nvim'
    },
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
      local wk = require('which-key')
      local function add_go_keybindings()
        wk.register({
            h = {
              name = 'Go Specific keybindings',
              c = { ':GoCmt<cr>', 'Add Doc comment' },
              d = { ':GoCheat ', 'Lookup cheat docs for function' },

              i = { ':GoImpl', 'Generate interface implementation' },
              e = { ':GoEnum ', 'Generate enum' },

              r = { ':GoGenReturn<cr>', 'Generate a return value (ie iferr)' },

              n = { ':GoNew<cr>', 'Create new file' },

              a = { ':GoAddTag<cr>', 'Add struct tags' },
              A = { ':GoRemoveTag<cr>', 'Remove struct tags' },

              s = { ':GoFillStruct<cr>', 'Fill struct fields' },
              S = { ':GoFillSwitch<cr>', 'Fill switch arms' },

              t = {
                name = 'Test',
                t = { ':GoTest<cr>', 'Run test' },
                f = { ':GoTestFunc<cr>', 'Run current test function' },
                F = { ':GoTestFile<cr>', 'Run current test file' },
              },

              R = {
                name = 'Refactor',
                m = { ':Gomvp ', 'Move/Rename package' },
              },
            },

            vr = { ':GoRename<cr>', 'Rename' },
          },
          { prefix = '<leader>' })
      end

      local function remove_go_keybindings()
        wk.register({
            h = {
              name = 'Go Specific keybindings',
              c = 'which_key_ignore',
              d = 'which_key_ignore',

              i = 'which_key_ignore',
              e = 'which_key_ignore',

              r = 'which_key_ignore',

              n = 'which_key_ignore',

              a = 'which_key_ignore',
              A = 'which_key_ignore',

              t = {
                t = 'which_key_ignore',
                f = 'which_key_ignore',
                F = 'which_key_ignore',
              },

              R = {
                name = 'Refactor',
                m = 'which_key_ignore',
              },
            },

            vr = { vim.lsp.buf.rename, 'Rename' },
          },
          { prefix = '<leader>' })
      end

      vim.api.nvim_create_autocmd('BufEnter', {
        pattern = '*.go',
        callback = add_go_keybindings,
      })

      vim.api.nvim_create_autocmd('BufLeave', {
        pattern = '*.go',
        callback = remove_go_keybindings,
      })

      require('go').setup({
        luasnip = true,
        trouble = true,
      })
    end,
    event = { 'CmdlineEnter' },
    ft = { 'go', 'gomod' },
    build = ':lua require("go.install").update_all_sync()' -- if you need to install/update all binaries
  },

  -- CSharp #
  {
    'Hoffs/omnisharp-extended-lsp.nvim',
  },

  -- Python and Jupyter
  -- Jupyter notebook evalation
  {
    'benlubas/molten-nvim',
    version = '^1.0.0', -- use version <2.0.0 to avoid breaking changes
    dependencies = {
      '3rd/image.nvim',
      'willothy/wezterm.nvim'
    },
    build = ':UpdateRemotePlugins',
    init = function()
      -- these are examples, not defaults. Please see the readme
      vim.g.molten_image_provider = 'image.nvim'
      vim.g.molten_output_win_max_height = 20
      -- vim.g.molten_auto_open_output = false
      -- vim.g.molten_image_provider = "image.nvim"

      vim.g.molten_wrap_output = true

      -- Output as virtual text. Allows outputs to always be shown, works with images, but can
      -- be buggy with longer images
      vim.g.molten_virt_text_output = true

      -- this will make it so the output shows up below the \`\`\` cell delimiter
      vim.g.molten_virt_lines_off_by_1 = true

      local wk = require('which-key')
      wk.register({
          h = {
            name = 'Jupyter Notebook Molten',
            e = { ':MoltenEvaluateLine<CR>', 'Evaluate cell' },
            E = { ':MoltenReevaluateCell<CR>', 'Reevaluate cell' },
            os = { ':noautocmd MoltenEnterOutput<CR>', 'Open output window' },
            h = { ':MoltenHideOutput<CR>', 'Hide output' },
            d = { ':MoltenDelete<CR>', 'Delete cell' },
            n = { ':MoltenNext<CR>', 'Next cell' },
            N = { ':MoltenPrev<CR>', 'Previous cell' },
            i = { ':MoltenInit<CR>', 'Initialize molten' },
          }
        },
        { prefix = '<leader>', silent = true })
      wk.register({
          h = {
            name = 'Jupyter Notebook Molten',
            v = { ':<C-u>MoltenEvaluateVisual<CR>gv', 'Evaluate visual selection' },
          }
        },
        { mode = 'v', prefix = '<leader>', silent = true })
    end,
  },
  -- Converting between ipynb and plain ju.py files
  {
    'GCBallesteros/jupytext.nvim',
    config = true,
    -- Depending on your nvim distro or config you may need to make the loading not lazy
    lazy = false,
  },
}

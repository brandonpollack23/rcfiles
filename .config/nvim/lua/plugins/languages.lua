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
  -- LSP output panel
  {
    'mhanberg/output-panel.nvim',
    config = function()
      require('output_panel').setup({})

      local wk = require('which-key')
      wk.add({
          { 'vP', ':OutputPanel<cr>', desc = 'Toggle LSP Output Panel' },
        },
        { prefix = '<leader>' }
      )
    end
  },

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
        -- nextls = {
        -- enable = false,
        -- cmd = vim.fn.expand('$HOME/.local/share/nvim/mason/bin/nextls'),
        -- experimental = {
        --   completions = {
        --     enable = true -- control if completions are enabled. defaults to false
        --   }
        -- }
        -- },

        elixirls = {
          repo = 'elixir-lsp/elixir-ls',
          enable = true,
          -- cmd = vim.fn.expand('$HOME/.local/share/nvim/mason/bin/elixir-ls'),
          settings = elixirls.settings {
            fetchDeps = true,
            enableTestLenses = true,
            suggestSpecs = true,
            dialyzerEnabled = true,
            incrementalDialyzer = true,
          },
          on_attach = function()
            wk.register({
                h = {
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
  {
    'synic/refactorex.nvim',
    ft = 'elixir',
    opts = {
      auto_update = true,
      pin_version = nil,
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
      local wk = require('which-key')
      local function add_go_keybindings()
        wk.register({
            h = {
              name = 'Go Specific keybindings',
              c = { ':GoCmt<cr>', 'Add Doc comment' },
              d = { ':GoCheat ', 'Lookup cheat docs for function' },

              i = { ':GoImplements<cr>', 'Get implementations of interface' },
              I = { ':GoImpl', 'Generate interface implementation' },
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

              I = 'which_key_ignore',
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
        lsp_cfg = {
          settings = {
            gopls = {
              analyses = {
                unusedparams = true,
              },
              buildFlags = { '-tags=all' },
              staticcheck = true,
              -- gofumpt = true, -- provided by golangci_lint ls
              codelenses = {
                generate = true,
                regenerate_cgo = true,
                tidy = true,
                upgrade_dependency = true,
              },
              hints = {
                assignVariableTypes = true,
                compositeLiteralFields = true,
                compositeLiteralTypes = true,
                constantValues = true,
                functionTypeParameters = true,
                parameterNames = true,
                rangeVariableTypes = true,
              }
            },
          },
        },
        luasnip = true,
        trouble = true,
        -- gofmt = 'gofumpt',
        -- max_line_len = 80,
      })
    end,
    event = { 'CmdlineEnter' },
    ft = { 'go', 'gomod' },
    build = ':lua require("go.install").update_all_sync()' -- if you need to install/update all binaries
  },

  -- Tailwind CSS
  -- tailwind-tools.lua
  {
    'luckasRanarison/tailwind-tools.nvim',
    name = 'tailwind-tools',
    build = ':UpdateRemotePlugins',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'VonHeikemen/lsp-zero.nvim',
      'nvim-telescope/telescope.nvim', -- optional
      'neovim/nvim-lspconfig',         -- optional
    },
    opts = {
      server = {
        settings = {
          experimental = {
            classRegex = { 'class(Name)?\\s*:\\s*\"([^\"]*)' }
          },
        },
      },
      conceal = {
        enabled = false,
        min_length = 80,
      },
    },
  },

  -- CSharp C#
  {
    'seblj/roslyn.nvim',
    dependencies = {
      'williamboman/mason.nvim',
    },
    ft = 'cs',
    opts = {
      config = {
        settings = {
          ['csharp|background_analysis'] = {
            dotnet_compiler_diagnostics_scope = 'fullSolution',
            dotnet_analyzer_diagnostics_scope = 'fullSolution',
          },
          ['csharp|completion'] = {
            dotnet_show_completion_items_from_unimported_namespaces = true,
            dotnet_show_name_completion_suggestions = true,
          },
          ['csharp|inlay_hints'] = {
            csharp_enable_inlay_hints_for_implicit_object_creation = true,
            csharp_enable_inlay_hints_for_implicit_variable_types = true,
            csharp_enable_inlay_hints_for_lambda_parameter_types = true,
            csharp_enable_inlay_hints_for_types = true,
            dotnet_enable_inlay_hints_for_indexer_parameters = true,
            dotnet_enable_inlay_hints_for_literal_parameters = true,
            dotnet_enable_inlay_hints_for_object_creation_parameters = true,
            dotnet_enable_inlay_hints_for_other_parameters = true,
            dotnet_enable_inlay_hints_for_parameters = true,
            dotnet_suppress_inlay_hints_for_parameters_that_differ_only_by_suffix = true,
            dotnet_suppress_inlay_hints_for_parameters_that_match_argument_name = true,
            dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent = true,
          },
          ['csharp|code_lens'] = {
            dotnet_enable_references_code_lens = true,
          },
        },
      },
    }
  },
  -- Typescript
  {
    'pmizio/typescript-tools.nvim',
    dependencies = { 'nvim-lua/plenary.nvim', 'neovim/nvim-lspconfig', 'VonHeikemen/lsp-zero.nvim' },
    opts = {
      settings = {
        tsserver_file_preferences = {
          includeInlayParameterNameHints = 'all', -- 'none' | 'literals' | 'all'
          includeInlayParameterNameHintsWhenArgumentMatchesName = false,
          includeInlayVariableTypeHints = true,
          includeInlayFunctionParameterTypeHints = true,
          includeInlayVariableTypeHintsWhenTypeMatchesName = false,
          includeInlayPropertyDeclarationTypeHints = true,
          includeInlayFunctionLikeReturnTypeHints = true,
          includeInlayEnumMemberValueHints = true,
        },
      },

      expose_as_code_actions = 'all',
      code_lens = 'all',
    }
  },
}

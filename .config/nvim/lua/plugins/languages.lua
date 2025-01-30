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
      require('output_panel').setup()

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
        nextls = {
          enable = false,
          -- cmd = vim.fn.expand('$HOME/.local/share/nvim/mason/bin/nextls'),
          -- experimental = {
          --   completions = {
          --     enable = true -- control if completions are enabled. defaults to false
          --   }
          -- }
        },

        elixirls = {
          enable = true,
          cmd = vim.fn.expand('$HOME/.local/share/nvim/mason/bin/elixir-ls'),
          settings = elixirls.settings {
            fetchDeps = false,
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

  -- Python and Jupyter
  -- Jupyter notebook sync
  {
    'kiyoon/jupynium.nvim',
    build = 'rye install .',
    config = function()
      local jupynium = require('jupynium')
      jupynium.setup({
        jupyter_command = { 'rye', 'run', 'jupyter', },
        jupynium_file_pattern = { '*.ju.*', '*.py' },
        auto_close_tab = false,
      })

      -- To sync a Jupynium file to an existing notebook,
      -- manually open the file in the browser,
      -- and :JupyniumStartSync 2 to sync to the 2nd tab (count from 1).
      local wk = require('which-key')
      local function setup_jupyter_keys()
        wk.register({
            h = {
              name = 'Jupyter Notebook',
              a = {
                function()
                  local file_path = vim.fn.expand('%:t')
                  local basename = vim.fn.fnamemodify(file_path, ':r')
                  -- if the file still ends in .ju, remove it
                  if string.sub(basename, -3) == '.ju' then
                    basename = string.sub(basename, 1, -4)
                  end
                  -- Read number input before and if there is one use that instead of basename.
                  local count = vim.api.nvim_get_vvar('count')
                  if count == 0 then
                    vim.notify('Starting sync for ' .. basename)
                    vim.cmd({ cmd = 'JupyniumStartSync', args = { basename } })
                  else
                    vim.cmd({ cmd = 'JupyniumStartSync', args = { count } })
                  end
                end,
                'Attach and open document'
              },
              s = {
                function()
                  vim.cmd('JupyniumStartAndAttachToServer')
                end,
                'Start jupynium server'
              },
              S = { function() vim.cmd('JupyniumStopSync') end, 'Stop sync' },
              r = { function() vim.cmd('JupyniumKernelRestart') end, 'Restart sync' },
              i = { function() vim.cmd('JupyniumKernelInterrupt') end, 'Interrupt' },
              d = { function()
                -- Insert "display(" at the beginning of the line and ")" at the end
                vim.cmd('normal! Idisplay(')
                vim.cmd('normal! A)')
                -- Insert newline and enter normal mode
                vim.cmd('normal! o')
              end, 'Make line a display command' }
            },
          },
          { prefix = '<leader>', silent = true })
        wk.register({
          ['<space>'] = {
            p = { ':JupyniumScrollUp<CR>', 'Scroll browser page up' },
            n = { ':JupyniumScrollDown<CR>', 'Scroll browser page down' },
          }
        })

        -- wk.register({
        --   ['<space>'] = {
        --     x = { function() vim.cmd('JupyniumExecuteSelectedCells') end, 'Jupyter Execute selected cells' },
        --     c = { function() vim.cmd('JupyniumClearSelectedCellsOutputs') end, 'Jupyter Clear selected cells' },
        --     k = { function() vim.cmd('JupyniumKernelHover') end, 'Jupyter Inspect a variable/hover' },
        --   }
        -- })
        -- wk.register({
        --   ['<space>'] = {
        --     x = { function() vim.cmd('JupyniumExecuteSelectedCells') end, 'Jupyter Execute selected cells' },
        --     c = { function() vim.cmd('JupyniumClearSelectedCellsOutputs') end, 'Jupyter Clear selected cells' },
        --   }
        -- }, { mode = 'v' })
      end

      -- Textobjects use [j and ]j for navigating cells. <space>jj to go to current sep,
      -- vaj,vij, etc for selecting cells
      vim.api.nvim_create_autocmd('BufEnter', {
        pattern = '*.ju.*',
        callback = function()
          setup_jupyter_keys()
        end,
      })

      wk.register({
          v = {
            j = {
              function()
                vim.cmd('JupyniumStartAndAttachToServer')
                setup_jupyter_keys()
              end,
              'Start Jupynium Server'
            }
          }
        },
        { prefix = '<leader>' })
    end,
  },
  
  -- Tailwind CSS
  -- tailwind-tools.lua
  {
    "luckasRanarison/tailwind-tools.nvim",
    name = "tailwind-tools",
    build = ":UpdateRemotePlugins",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-telescope/telescope.nvim", -- optional
      "neovim/nvim-lspconfig", -- optional
    },
    opts = {} -- your configuration
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
    "pmizio/typescript-tools.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
    opts = {
      settings = {
        tsserver_file_preferences = {
          includeInlayParameterNameHints = "all", -- 'none' | 'literals' | 'all'
          includeInlayParameterNameHintsWhenArgumentMatchesName = false,
          includeInlayVariableTypeHints = true,
          includeInlayFunctionParameterTypeHints = true,
          includeInlayVariableTypeHintsWhenTypeMatchesName = false,
          includeInlayPropertyDeclarationTypeHints = true,
          includeInlayFunctionLikeReturnTypeHints = true,
          includeInlayEnumMemberValueHints = true,
        },
      },

      expose_as_code_actions = "all",
      code_lens = "all",
    }
  },
  -- Jupyter notebook evalation
  -- {
  --   'benlubas/molten-nvim',
  --   version = '^1.0.0', -- use version <2.0.0 to avoid breaking changes
  --   dependencies = {
  --     '3rd/image.nvim',
  --     'willothy/wezterm.nvim'
  --   },
  --   build = ':UpdateRemotePlugins',
  --   init = function()
  --     -- these are examples, not defaults. Please see the readme
  --     vim.g.molten_image_provider = 'wezterm'
  --     vim.g.molten_output_win_max_height = 20
  --     vim.g.molten_auto_open_output = false
  --
  --     vim.g.molten_wrap_output = true
  --
  --     -- Output as virtual text. Allows outputs to always be shown, works with images, but can
  --     -- be buggy with longer images
  --     vim.g.molten_virt_text_output = true
  --
  --     -- this will make it so the output shows up below the \`\`\` cell delimiter
  --     vim.g.molten_virt_lines_off_by_1 = true
  --
  --     local wk = require('which-key')
  --     wk.register({
  --         h = {
  --           name = 'Jupyter Notebook Molten',
  --           e = { ':MoltenEvaluateLine<CR>', 'Evaluate cell' },
  --           E = { ':MoltenReevaluateCell<CR>', 'Reevaluate cell' },
  --           os = { ':noautocmd MoltenEnterOutput<CR>', 'Open output window' },
  --           h = { ':MoltenHideOutput<CR>', 'Hide output' },
  --           d = { ':MoltenDelete<CR>', 'Delete cell' },
  --           n = { ':MoltenNext<CR>', 'Next cell' },
  --           N = { ':MoltenPrev<CR>', 'Previous cell' },
  --           i = { ':MoltenInit<CR>', 'Initialize molten' },
  --         }
  --       },
  --       { prefix = '<leader>', silent = true })
  --     wk.register({
  --         h = {
  --           name = 'Jupyter Notebook Molten',
  --           v = { ':<C-u>MoltenEvaluateVisual<CR>gv', 'Evaluate visual selection' },
  --         }
  --       },
  --       { mode = 'v', prefix = '<leader>', silent = true })
  --   end,
  -- },
  -- -- Converting between ipynb and plain ju.py files
  -- {
  --   'GCBallesteros/jupytext.nvim',
  --   config = true,
  --   -- Depending on your nvim distro or config you may need to make the loading not lazy
  --   lazy = false,
  -- },
}

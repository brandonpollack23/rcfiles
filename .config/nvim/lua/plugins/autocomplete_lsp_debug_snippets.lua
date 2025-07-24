return {
  {
    'williamboman/mason.nvim',
    config = function()
      -- Browse and install more with :Mason
      -- to learn how to use mason.nvim with lsp-zero
      -- read this: https://github.com/VonHeikemen/lsp-zero.nvim/blob/v3.x/doc/md/guide/integrate-with-mason-nvim.md
      require('mason').setup({
        registries = {
          'github:mason-org/mason-registry',
          'github:Crashdummyy/mason-registry', -- for roslyn csharp c#
        }
      })
    end
  },
  {
    'VonHeikemen/lsp-zero.nvim',
    branch = 'v4.x',
    dependencies = {
      'L3MON4D3/LuaSnip',
      'b0o/SchemaStore.nvim',
      'folke/neoconf.nvim', -- neoconf wants to be set up before any LSPs
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-path',
      'hrsh7th/nvim-cmp',
      'neovim/nvim-lspconfig',
      'williamboman/mason-lspconfig.nvim',
      'williamboman/mason.nvim',
    },
    config = function()
      local cmp_nvim_lsp = require('cmp_nvim_lsp')
      local lsp_zero = require('lsp-zero')
      local lspconfig = require('lspconfig')
      local mason_lspconfig = require('mason-lspconfig')
      local mason_registry = require('mason-registry')

      local lsp_attach = function(client, bufnr)
        -- see :help lsp-zero-keybindings
        -- to learn the available actions
        lsp_zero.default_keymaps({ buffer = bufnr })
      end

      lsp_zero.extend_lspconfig({
        capabilities = cmp_nvim_lsp.default_capabilities(),
        lsp_attach = lsp_attach,
        float_border = 'rounded',
        sign_text = true,
      })

      lsp_zero.on_attach(function(client, bufnr)
        -- see :help lsp-zero-keybindings
        -- to learn the available actions
        lsp_zero.default_keymaps({ buffer = bufnr })
      end)

      lsp_zero.set_sign_icons({
        error = '✘',
        warn = '▲',
        hint = '⚑',
        info = '»'
      })

      local ensure_installed_lsps = {
        'bashls',
        'clangd',
        'eslint',
        'gopls',
        'golangci_lint_ls',
        'htmx',
        'jsonls',
        -- 'omnisharp_mono', replaced in languages.lua
        'lua_ls',
        -- 'nextls', -- another elixir language server
        'ruff', -- python linter (fast)
        'rust_analyzer',
        -- 'roslyn', -- csharp
        'taplo',
        'tailwindcss',
        'templ',
        'zls',
      }

      -- needed for non mapped lsps in mason-lspconfig
      local ensure_installed_mason = { 'golangci-lint' }

      -- Add lsps not supported on windows
      if vim.fn.has('win32') ~= 1 then
        table.insert(ensure_installed_lsps, 'elp')
      end

      for _, p in pairs(ensure_installed_mason) do
        local pkg = mason_registry.get_package(p)
        if not pkg:is_installed() then
          pkg:install()
        end
      end
      mason_lspconfig.setup({
        -- Anything you always want installed add to this list, otherwise you need to use Mason to install.
        -- Everything is enabled by the lsp_zero.default_setup below, but you can customize them as I have done with lua_ls if necessary.
        -- Each of their docs are in lspconfig or their own docs.
        ensure_installed = ensure_installed_lsps,
        automatic_installation = false,
        handlers = {
          lsp_zero.default_setup,

          ['astro'] = function()
            lspconfig.astro.setup()
          end,

          ['clangd'] = function()
            lspconfig.clangd.setup {
              cmd = { 'clangd', '--pch-storage=memory' },
              filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' }, -- exclude "proto"
            }
          end,

          ['rust_analyzer'] = function()
            lspconfig.rust_analyzer.setup({
              settings = {
                ['rust-analyzer'] = {
                  -- cargo = {
                  --   features = { 'all' },
                  -- },
                  rustfmt = {
                    extraArgs = { '+nightly' },
                  },
                  -- check = {
                  --   command = 'clippy',
                  -- },
                  checkOnSave = true,
                  inlayHints = {
                    closureReturnTypeHints = {
                      enable = 'always',
                    }
                  },
                  workspace = {
                    symbol = {
                      search = {
                        scope = 'workspace_and_dependencies',
                      },
                    }
                  },
                  semanticHighlighting = {
                    operator = {
                      specialization = {
                        enable = true,
                      },
                    },
                    punctuation = {
                      enable = true,
                    },
                  }
                },
              },
            })
          end,
          -- Lua config
          ['lua_ls'] = function()
            lspconfig.lua_ls.setup {
              on_init = function(client)
                client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
                  runtime = {
                    -- Tell the language server which version of Lua you're using
                    -- (most likely LuaJIT in the case of Neovim)
                    version = 'LuaJIT'
                  },
                  -- Make the server aware of Neovim runtime files
                  workspace = {
                    checkThirdParty = 'Ask',
                    -- None of this is needed because lazydev handles it
                    --
                    -- library = {
                    --   vim.env.VIMRUNTIME
                    --   -- Depending on the usage, you might want to add additional paths here.
                    --   -- "${3rd}/luv/library"
                    --   -- "${3rd}/busted/library",
                    -- }
                    -- or pull in all of 'runtimepath'. NOTE: this is a lot slower
                    -- TODO NOW uncomment
                    -- library = {
                    --   vim.api.nvim_get_runtime_file('', true),
                    --   '${3rd}/luassert/library',
                    --   '${3rd}/luv/library',
                    --   '${3rd}/busted/library',
                    -- },
                  },
                })
              end,
              settings = {
                Lua = {
                }
              }
            }
          end,

          -- handled by ray-x/go.nvim
          -- ['gopls'] = function()
          --   lspconfig.gopls.setup {
          --     cmd_env = { GOFUMPT_SPLIT_LONG_LINES = 'on' },
          --     on_init = function()
          --       vim.api.nvim_create_autocmd('BufWritePre', {
          --         pattern = '*.go',
          --         callback = function()
          --           local params = vim.lsp.util.make_range_params()
          --           params.context = { only = { 'source.organizeImports' } }
          --           -- buf_request_sync defaults to a 1000ms timeout. Depending on your
          --           -- machine and codebase, you may want longer. Add an additional
          --           -- argument after params if you find that you have to write the file
          --           -- twice for changes to be saved.
          --           -- E.g., vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 3000)
          --           local result = vim.lsp.buf_request_sync(0, 'textDocument/codeAction', params)
          --           for cid, res in pairs(result or {}) do
          --             for _, r in pairs(res.result or {}) do
          --               if r.edit then
          --                 local enc = (vim.lsp.get_client_by_id(cid) or {}).offset_encoding or 'utf-16'
          --                 vim.lsp.util.apply_workspace_edit(r.edit, enc)
          --               end
          --             end
          --           end
          --           -- vim.lsp.buf.format({ async = false })
          --         end
          --       })
          --     end,
          --
          --     settings = {
          --       gopls = {
          --         analyses = {
          --           unusedparams = true,
          --         },
          --         buildFlags = { '-tags=all' },
          --         staticcheck = true,
          --         -- gofumpt = true, -- provided by golangci_lint ls
          --         codelenses = {
          --           generate = true,
          --           regenerate_cgo = true,
          --           tidy = true,
          --           upgrade_dependency = true,
          --         },
          --         hints = {
          --           assignVariableTypes = true,
          --           compositeLiteralFields = true,
          --           compositeLiteralTypes = true,
          --           constantValues = true,
          --           functionTypeParameters = true,
          --           parameterNames = true,
          --           rangeVariableTypes = true,
          --         }
          --       },
          --     },
          --   }
          -- end,

          ['golangci_lint_ls'] = function()
            lspconfig.golangci_lint_ls.setup {
              filetypes = { 'go', 'gomod' },
              cmd = { vim.fn.expand('$HOME/.local/share/nvim/mason/bin/golangci-lint-langserver') },
              root_dir = lspconfig.util.root_pattern('go.work', 'go.mod', '.git', '.golangci.yml', '.golangci.yaml', '.golangci.toml', '.golangci.json'),
              init_options = {
                command = { 'golangci-lint', 'run', '--out-format', 'json' }
              }
            }
          end,

          ['pyright'] = function()
            lspconfig.pyright.setup {
              -- cmd = { 'rye run basedpyright' },
              settings = {
                pyright = {
                  autoImportCompletion = true,
                  disableLanguageServices = false,
                  disableOrganizeImports = false,
                  disableTaggedHints = false,

                  analysis = {
                    autoImportCompletions = true,
                    autoSearchPaths = true,
                    diagnosticMode = 'workspace',
                    useLibraryCodeForTypes = true,
                    typeCheckingMode = 'all'
                  }
                },
              }
            }
          end,

          -- handled by elixir-tools, mason is used for debugging only.
          -- ['elixirls'] = function()
          -- end,

          ['jsonls'] = function()
            lspconfig.jsonls.setup {
              settings = {
                json = {
                  schemas = require('schemastore').json.schemas(),
                  validate = { enable = true },
                },
              },
            }
          end,
        },
      })

      -- Haskell toolchain is finicky so I should use the installed version and warn if i go into a haskell file and it isn't set up.
      lspconfig['hls'].setup({
        cmd = { 'stack', 'exec', 'haskell-language-server-wrapper', '--', '--lsp' },
        -- settings = {
        -- haskell = {
        --   -- formattingProvider = "ormolu"
        -- }
        -- }
      })
      vim.api.nvim_create_autocmd('BufEnter', {
        pattern = { '*.hs' },
        callback = function()
          if vim.fn.executable('haskell-language-server-wrapper') ~= 1 then
            vim.notify(
              'Haskell Language Server (hls) is not installed. Please install it with `gchup install haskell-language-server`',
              vim.log.levels.WARN)
          end
        end
      })

      -- Gleam setup
      lspconfig.gleam.setup({})

      -- godot gdscript
      lspconfig.gdscript.setup({})

      -- postgrestools postgres_lsp
      lspconfig.postgres_lsp.setup({})

      local cmp = require('cmp')
      local cmp_select = { behaviour = cmp.SelectBehavior.Select }
      local cmp_mappings = {
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<C-k>'] = cmp.mapping.select_prev_item(cmp_select),
        ['<C-j>'] = cmp.mapping.select_next_item(cmp_select),
        ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
        ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),

        ['<C-y>'] = cmp.mapping.confirm({
          behavior = cmp.ConfirmBehavior.Insert,
          select = true,
        }),

        ['<C-e>'] = cmp.mapping.close(),
        ['<C-u>'] = cmp.mapping.scroll_docs(-4),
        ['<C-d>'] = cmp.mapping.scroll_docs(4),
        ['<CR>'] = cmp.mapping.confirm({
          behavior = cmp.ConfirmBehavior.Insert,
          select = true,
        }),

        ['<Tab>'] = cmp.mapping(function(fallback)
          local luasnip = require('luasnip')

          if cmp.visible() then
            cmp.select_next_item({ behavior = cmp.SelectBehavior.Insert })
          elseif luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          else
            fallback()
          end
        end, { 'i', 's' }),

        ['<S-Tab>'] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          elseif luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { 'i', 's' }),
      }

      cmp.setup({
        window = {},
        mapping = cmp.mapping.preset.insert(cmp_mappings),
        sources = {
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
          { name = 'path' },
          { name = 'jupynium' },
          { name = 'buffer' },
        },
      })

      -- Use LSP for these things if it exists, otherwise use vim's built in
      lsp_zero.on_attach(function(client, bufnr)
        local wk = require('which-key')
        local telescopeBuiltin = require('telescope.builtin')

        wk.add({
          { 'gd', vim.lsp.buf.definition,   desc = 'Go to definition',    buffer = bufnr, remap = false },
          { 'K',  vim.lsp.buf.hover,        desc = 'Hover Information',   buffer = bufnr, remap = false },
          { '[d', vim.diagnostic.goto_next, desc = 'Next diagnostic',     buffer = bufnr, remap = false },
          { ']d', vim.diagnostic.goto_prev, desc = 'Previous diagnostic', buffer = bufnr, remap = false },
        })

        wk.add({
          { '<leader>v',   group = 'LSP/IDE Operations',                                                  buffer = bufnr,                           remap = false },
          { '<leader>vws', telescopeBuiltin.workspace_symbols,                                            desc = 'Workspace symbols',               buffer = bufnr, remap = false },
          { '<leader>vd',  vim.diagnostic.open_float,                                                     desc = 'Open diagnostic floating window', buffer = bufnr, remap = false },
          { '<leader>vc',  vim.lsp.buf.code_action,                                                       desc = 'Open code actions',               buffer = bufnr, remap = false },
          { '<leader>vr',  vim.lsp.buf.rename,                                                            desc = 'Rename',                          buffer = bufnr, remap = false },
          { '<leader>vR',  telescopeBuiltin.lsp_references,                                               desc = 'Open references',                 buffer = bufnr, remap = false },
          { '<leader>vh',  function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled()) end, desc = 'Toggle inlay hints',              buffer = bufnr, remap = false },
        })

        wk.add({
          { '<leader>v',  group = 'LSP/IDE Operations', mode = 'x',                 buffer = bufnr, remap = false },
          { '<leader>vc', vim.lsp.buf.code_action,      desc = 'Open code actions', mode = 'x',     buffer = bufnr, remap = false },
        })

        wk.add({
          { '<C-q>', vim.lsp.buf.hover,                           desc = 'Code hover',     mode = 'i' },
          { '<C-.>', vim.lsp.buf.code_action,                     desc = 'Code action',    mode = 'i' },
          { '<C-k>', function() vim.lsp.buf.signature_help() end, desc = 'Signature help', mode = 'i' },
        })

        wk.add({
          { '<C-q>', vim.lsp.buf.hover,                           desc = 'Code hover',     mode = 'n' },
          { '<C-.>', vim.lsp.buf.code_action,                     desc = 'Code action',    mode = 'n' },
          { '<C-k>', function() vim.lsp.buf.signature_help() end, desc = 'Signature help', mode = 'n' },
        })
      end)

      lsp_zero.setup()

      -- Diagnostics
      vim.diagnostic.config({
        virtual_text = { severity = { min = vim.diagnostic.severity.INFO } },
        underline = true,
      })

      -- Lsp hints etc
      vim.api.nvim_set_hl(0, 'LspCodeLens', { italic = true, fg = '#7a7a7a' })
      vim.api.nvim_set_hl(0, 'LspCodeLensSeparator', { fg = '#7a7a7a' })

      local lspGroup = vim.api.nvim_create_augroup('UserLspConfig', {})
      vim.api.nvim_create_autocmd('LspAttach', {
        group = lspGroup,
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client == nil then
            return
          end

          if client.server_capabilities.inlayHintProvider then
            vim.lsp.inlay_hint.enable(true)
          end

          if client.server_capabilities.codeLensProvider then
            vim.api.nvim_create_autocmd('CursorHold', {
              group = lspGroup,
              pattern = '*.ex',
              callback = function(_)
                -- swallow any error
                -- temporarily disable vim notify for this call
                local notifyBackup = vim.notify
                vim.notify = function() end
                pcall(vim.lsp.codelens.refresh)
                vim.notify = notifyBackup
              end
            })

            require('which-key').add({
              { '<leader>v',  group = 'LSP/IDE Operations' },
              { '<leader>vl', vim.lsp.codelens.run,        desc = 'Display code lens' },
              { '<leader>vL', vim.lsp.codelens.refresh,    desc = 'Refresh code lens' },
            })
          end
        end
      })

      -- Make all code lenses on the previous line like in vscode
      -- TODO when im not fucked to do this, look into extmark and see if i can modify neovim to handle this and put it above directly
      -- https://github.com/neovim/neovim/blob/8e5c48b08dad54706500e353c58ffb91f2684dd3/runtime/lua/vim/lsp/codelens.lua#L174C11-L174C31
      -- local original_code_lens = vim.lsp.codelens.on_codelens
      -- vim.lsp.codelens.on_codelens = function(err, result, ctx, config)
      --   if result == nil then
      --     return
      --   end
      --
      --   for _, codeLens in pairs(result) do
      --     local line = codeLens.range.start.line
      --     codeLens.range.start.line = line - 1
      --     -- codeLens.command.title = '\n' .. codeLens.command.title
      --     -- get first character column of the current line
      --     local firstNonWhitespace = string.find(vim.fn.getline(line), '[^[:space:]]')
      --     codeLens.range.start.character = firstNonWhitespace
      --   end
      --
      --   original_code_lens(err, result, ctx, config)
      -- end
    end
  },
  {
    'ray-x/lsp_signature.nvim',
    event = 'VeryLazy',
    opts = {
      hint_enable = false,
      handler_opts = {
        border = 'rounded',
      }
    },
    config = function(_, opts) require 'lsp_signature'.setup(opts) end
  },
  {
    'L3MON4D3/LuaSnip',
    dependencies = { 'rafamadriz/friendly-snippets', 'saadparwaiz1/cmp_luasnip', 'benfowler/telescope-luasnip.nvim' },
    config = function()
      require('luasnip.loaders.from_vscode').lazy_load({
        exclude = { 'go' },
      })
      -- require('brpol.snippets.first_snippet')
      require('brpol.snippets.date')
      require('luasnip.loaders.from_vscode').lazy_load({ paths = { '../brpol/snippets/vscode_style' } })

      vim.api.nvim_create_autocmd('BufEnter', {
        pattern = { '*.py' },
        callback = function()
          require('brpol.snippets.jupytext')
          require('brpol.snippets.python')
        end
      }
      )
      require('telescope').load_extension('luasnip')

      -- Tab is set up to balance between all its uses in remap.lua
      local luasnip = require('luasnip')
      require('which-key').add({
        {
          '<M-n>',
          function() if luasnip.choice_active() then return luasnip.change_choice(1) end end,
          desc = 'Next snippet choice',
          mode = 'i'
        },
        {
          '<M-p>',
          function() if luasnip.choice_active() then return luasnip.change_choice(-1) end end,
          desc = 'Previous snippet choice',
          mode = 'i'
        },
      })
    end
  },
  -- Causing bugs in unity
  -- {
  --   'mhanberg/output-panel.nvim',
  --   event = 'VeryLazy',
  --   config = function()
  --     require('output_panel').setup()
  --   end
  -- },

  -- Refactor stuff when LSP doesnt work
  {
    'ThePrimeagen/refactoring.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
      'nvim-telescope/telescope.nvim',
    },
    config = function()
      require('refactoring').setup()
      require('telescope').load_extension('refactoring')

      local wk = require('which-key')

      -- Visual mode refactoring
      wk.add({
        { '<leader>R',  group = 'Refactors',                                     mode = 'x' },
        { '<leader>Re', ':Refactor extract<CR>',                                 desc = 'Extract function',         mode = 'x' },
        { '<leader>Rf', ':Refactor extract_to_file<CR>',                         desc = 'Extract function to file', mode = 'x' },
        { '<leader>Rv', ':Refactor extract_var<CR>',                             desc = 'Extract variable',         mode = 'x' },
        { '<leader>Rr', function() require('refactoring').select_refactor() end, desc = 'Select refactor',          mode = 'x' },
        { '<leader>Ri', ':Refactor inline_var<CR>',                              desc = 'Inline variable',          mode = 'x' },
        { '<leader>RB', ':Refactor extract_block_to_file<CR>',                   desc = 'Extract block to file',    mode = 'x' },
      })

      -- Normal mode refactoring
      wk.add({
        { '<leader>R',  group = 'Refactors',                                     mode = 'n' },
        { '<leader>Rr', function() require('refactoring').select_refactor() end, desc = 'Select refactor',       mode = 'n' },
        { '<leader>Ri', ':Refactor inline_var<CR>',                              desc = 'Inline variable',       mode = 'n' },
        { '<leader>RB', ':Refactor extract_block_to_file<CR>',                   desc = 'Extract block to file', mode = 'n' },
        { '<leader>RI', ':Refactor inline_func<CR>',                             desc = 'Inline function',       mode = 'n' },
        { '<leader>Rb', ':Refactor extract_block<CR>',                           desc = 'Extract block',         mode = 'n' },
      })
    end,
  },

  {
    'antosha417/nvim-lsp-file-operations',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-neo-tree/neo-tree.nvim',
    },
    config = function()
      require('lsp-file-operations').setup()
    end,
  },
  {
    'Exafunction/windsurf.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'hrsh7th/nvim-cmp',
    },
    config = function()
      require('codeium').setup({
        virtual_text = {
          enabled = true
        }
      })

      local wk = require('which-key')

      wk.add({
        { '<leader>c',  group = 'AI Operations', mode = 'n' },
        { '<leader>co', ':Codeium Chat<CR>',     desc = 'Codeium Chat', mode = 'n' },
      })
    end
  },
}

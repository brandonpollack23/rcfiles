-- Function that detects if there is a "cmd" directory in the project root and walks the files in there to see if there is a main function in a main package in any go files there and returns the list of them
local function get_go_main_files()
  vim.notify(
    'Searching for main files in cmd directory, if there are more you will need to add them manually to a launch.json or a local nvim configuration',
    vim.log.levels.TRACE)

  local cmd_dir = './cmd'
  local main_files = {}
  if vim.fn.isdirectory(cmd_dir) == 0 then
    return main_files
  end

  local files = vim.fn.readdir(cmd_dir)
  for _, file in ipairs(files) do
    local full_path = cmd_dir .. '/' .. file
    vim.notify('Checking file: ' .. full_path, vim.log.levels.TRACE)
    if vim.fn.isdirectory(full_path) == 0 then
      local file_contents = vim.fn.readfile(full_path)
      for _, line in ipairs(file_contents) do
        if string.match(line, '^%s*func main') then
          table.insert(main_files, full_path)
          break
        end
      end
    end
  end

  return main_files
end

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
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-path',
      'hrsh7th/nvim-cmp',
      'neovim/nvim-lspconfig',
      'williamboman/mason-lspconfig.nvim',
      'williamboman/mason.nvim',
      'folke/neoconf.nvim', -- neoconf wants to be set up before any LSPs
      'L3MON4D3/LuaSnip',
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
        'elixirls', -- handled by elixir-tools, used for debugging
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

          ['elixirls'] = function()
            -- handled by elixir-tools, mason is used for debugging only.
          end
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

      local copilot = require('copilot.suggestion')
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
          elseif copilot.is_visible() then
            copilot.accept()
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

        wk.register({
            gd = { vim.lsp.buf.definition, 'Go to definition' },
            K = { vim.lsp.buf.hover, 'Hover Information' },
            ['[d'] = { vim.diagnostic.goto_next, 'Next diagnostic' },
            [']d'] = { vim.diagnostic.goto_prev, 'Previous diagnostic' },
          },
          { buffer = bufnr, noremap = true }
        )

        wk.register({
            v = {
              name = 'LSP/IDE Operations',
              ws = { telescopeBuiltin.workspace_symbols, 'Workspace symbols' },
              d = { vim.diagnostic.open_float, 'Open diagnostic floating window' },
              c = { vim.lsp.buf.code_action, 'Open code actions' },
              r = { vim.lsp.buf.rename, 'Rename' },
              R = { telescopeBuiltin.lsp_references, 'Open references' },
              h = { function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled()) end, 'Toggle inlay hints' }
            },
          },
          { buffer = bufnr, noremap = true, prefix = '<leader>' }
        )

        wk.register({
            v = {
              name = 'LSP/IDE Operations',
              c = { vim.lsp.buf.code_action, 'Open code actions' },
            },
          },
          { mode = 'x', buffer = bufnr, noremap = true, prefix = '<leader>' }
        )

        wk.register(
          {
            ['<C-q>'] = { vim.lsp.buf.hover, 'Code hover' },
            ['<C-.>'] = { vim.lsp.buf.code_action, 'Code action' },
            ['<C-k>'] = { function() vim.lsp.buf.signature_help() end, 'Signature help' },
          },
          { mode = 'i' }
        )
        wk.register(
          {
            ['<C-q>'] = { vim.lsp.buf.hover, 'Code hover' },
            ['<C-.>'] = { vim.lsp.buf.code_action, 'Code action' },
            ['<C-k>'] = { function() vim.lsp.buf.signature_help() end, 'Signature help' },
          },
          { mode = 'n' }
        )
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

            require('which-key').register({
              v = {
                name = 'LSP/IDE Operations',
                l = { vim.lsp.codelens.run, 'Display code lens' },
                L = { vim.lsp.codelens.refresh, 'Refresh code lens' },
              },
            }, { prefix = '<leader>' })
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
      require('which-key').register({
          ['<M-n>'] = {
            function() if luasnip.choice_active() then return luasnip.change_choice(1) end end,
            'Next snippet choice' },
          ['<M-p>'] = {
            function() if luasnip.choice_active() then return luasnip.change_choice(-1) end end,
            'Previous snippet choice' },
        },
        { mode = 'i' }
      )
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
      wk.register({
          R = {
            name = 'Refactors',
            e = { ':Refactor extract<CR>', 'Extract function' },
            f = { ':Refactor extract_to_file<CR>', 'Extract function to file' },
            v = { ':Refactor extract_var<CR>', 'Extract variable' },
          }
        },
        {
          mode = 'x',
          prefix = '<leader>',
        })

      local sharedBindings = {
        R = {
          name = 'Refactors',
          r = { function() require('refactoring').select_refactor() end, 'Select refactor' },
          i = { ':Refactor inline_var<CR>', 'Inline variable' },
          B = { ':Refactor extract_block_to_file<CR>', 'Extract block to file' },
        }
      }
      wk.register(sharedBindings,
        {
          mode = 'x',
          prefix = '<leader>',
        })
      wk.register(sharedBindings,
        {
          mode = 'n',
          prefix = '<leader>',
        })

      wk.register({
          R = {
            name = 'Refactors',
            I = { ':Refactor inline_func<CR>', 'Inline function' },
            b = { ':Refactor extract_block<CR>', 'Extract block' },
          }
        },
        {
          mode = 'n',
          prefix = '<leader>',
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

  -- Github copilot
  {
    'zbirenbaum/copilot.lua',
    build = function()
      vim.cmd('Copilot auth')
    end,
    config = function()
      local copilot = require('copilot')
      copilot.setup({
        panel = {
          auto_refresh = true,
          keymap = {
            open = '<C-l>',
          }
        },
        suggestion = {
          enabled = true,
          auto_trigger = true,
          keymap = {
            -- Accept is bound in remap.lua so <Tab> can be used for completion of snippets etc as well.
            accept = '<M-a>',
            accept_word = '<M-Right>',
            next = '<M-]>',
            prev = '<M-[>',
            dismiss = '<M-d>',
          },
          filetypes = {
            ['*'] = false, -- disabled by default
          }
        }
      })

      vim.cmd('Copilot enable')
      local copilotEnabled = true
      local function copilot_toggle()
        copilotEnabled = not copilotEnabled
        if copilotEnabled then
          vim.cmd('Copilot enable')
        else
          vim.cmd('Copilot disable')
        end
      end
      require('which-key').register({
          c = {
            name = 'Github Copilot Operations',
            T = { copilot_toggle, 'Toggle Copilot' },
          },
        },
        { prefix = '<leader>' }
      )

      -- Copilot colors
      vim.cmd('hi CopilotSuggestion guifg=Gray')
      vim.cmd('hi CopilotAnnotation guifg=Gray')
    end
  },
  {
    'CopilotC-Nvim/CopilotChat.nvim',
    dependencies = {
      { 'zbirenbaum/copilot.lua' }, -- or github/copilot.vim
      { 'nvim-lua/plenary.nvim' },  -- for curl, log wrapper
    },
    branch = 'main',
    -- TODO copy paste this and put it in it's own file: https://github.com/jellydn/lazy-nvim-ide/blob/main/lua/plugins/extras/copilot-chat-v2.lua
    config = function()
      local chat = require('CopilotChat')
      local select = require('CopilotChat.select')

      -- if the working directory has a .vscode/copilot_instructions directory add each file as a new prompt directory.
      local prompts = {}
      local copilot_instructions_dir = './.vscode/copilot_instructions/'
      if vim.fn.isdirectory(copilot_instructions_dir) then
        for _, filePath in ipairs(vim.fn.readdir(copilot_instructions_dir)) do
          local lines = vim.fn.readfile(copilot_instructions_dir .. filePath .. '/prompt.md')
          local prompt_contents = table.concat(lines, '\n') .. require('CopilotChat.config.prompts').COPILOT_BASE.system_prompt
          local description_contents = vim.fn.readfile(copilot_instructions_dir .. filePath .. '/description.md')
          prompts[filePath] = {
            system_prompt = prompt_contents,
            description = description_contents,
          }
        end
      end

      chat.setup({
        model = 'gemini-2.5-pro',
        prompts = prompts,
        -- window = {
        --   layout = 'float'
        -- }
      })

      vim.api.nvim_create_user_command('CopilotChatInline', function(args)
        chat.ask(args.args, {
          selection = select.visual,
          window = {
            layout = 'float',
            relative = 'cursor',
            width = 1,
            height = 0.2,
            row = 1,
          },
        })
      end, { nargs = '*', range = true })

      local wk = require('which-key')
      wk.register({
          c = {
            name = 'Github Copilot Operations',
            c = { ':CopilotChatInline<cr>', 'CopilotChat - Chat with current buffer' },
            e = { ':CopilotChatExplain<cr>', 'CopilotChat - Explain code' },
            gt = { ':CopilotChatTests<cr>', 'CopilotChat - Generate tests' },
            f = { ':CopilotChatFix<cr>', 'CopilotChat - Fix diagnostic', },
            R = { ':CopilotChatReset<cr>', 'CopilotChat - Reset chat history and clear buffer' },
            o = { ':CopilotChatOpen<cr>', 'Open CopilotChat' },
            x = { ':CopilotChatClose<cr>', 'Close CopilotChat' },
            d = { ':CopilotChatFixDocs<cr>', 'CopilotChat generate documentation' },
          }
        },
        {
          mode = { 'n', 'x' },
          prefix = '<leader>',
          silent = true,
          noremap = true,
          nowait = false,
        })
    end
  },
  -- {
  --   'supermaven-inc/supermaven-nvim',
  --   config = function()
  --     require('supermaven-nvim').setup({
  --       keymaps = {
  --         accept_suggestion = '<Tab>',
  --         clear_suggestion = '<C-]>',
  --         accept_word = '<C-j>',
  --       },
  --       ignore_filetypes = { cpp = true },
  --       color = {
  --         suggestion_color = '#808080',
  --         cterm = 244,
  --       },
  --       disable_inline_completion = false, -- disables inline completion for use with cmp
  --       disable_keymaps = false            -- disables built in keymaps for more manual control
  --     })
  --   end,
  -- },
}

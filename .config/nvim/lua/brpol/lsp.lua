local lsp_zero = require('lsp-zero')
local lspconfig = require('lspconfig')

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

-- Browse and install more with :Mason
-- to learn how to use mason.nvim with lsp-zero
-- read this: https://github.com/VonHeikemen/lsp-zero.nvim/blob/v3.x/doc/md/guide/integrate-with-mason-nvim.md
require('mason').setup()
require('mason-lspconfig').setup({
  -- Anything you always want installed add to this list, otherwise you need to use Mason to install.
  -- Everything is enabled by the lsp_zero.default_setup below, but you can customize them as I have done with lua_ls if necessary.
  -- Each of their docs are in lspconfig or their own docs.
  ensure_installed = {
    'bashls',
    'elixirls',
    'elp', -- erlang
    'eslint',
    'gopls',
    'golangci_lint_ls',
    'jsonls',
    'lua_ls',
    -- 'nextls', -- another elixir language server
    'rust_analyzer',
    'tsserver',
    'zls',
  },


  automatic_installation = true,

  handlers = {
    lsp_zero.default_setup,

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
              -- None of this is needed because neodev handles it
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

    ['gopls'] = function()
      lspconfig.gopls.setup {
        on_init = function()
          vim.api.nvim_create_autocmd('BufWritePre', {
            pattern = '*.go',
            callback = function()
              local params = vim.lsp.util.make_range_params()
              params.context = { only = { 'source.organizeImports' } }
              -- buf_request_sync defaults to a 1000ms timeout. Depending on your
              -- machine and codebase, you may want longer. Add an additional
              -- argument after params if you find that you have to write the file
              -- twice for changes to be saved.
              -- E.g., vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 3000)
              local result = vim.lsp.buf_request_sync(0, 'textDocument/codeAction', params)
              for cid, res in pairs(result or {}) do
                for _, r in pairs(res.result or {}) do
                  if r.edit then
                    local enc = (vim.lsp.get_client_by_id(cid) or {}).offset_encoding or 'utf-16'
                    vim.lsp.util.apply_workspace_edit(r.edit, enc)
                  end
                end
              end
              vim.lsp.buf.format({ async = false })
            end
          })
        end,

        settings = {
          gopls = {
            analyses = {
              unusedparams = true,
            },
            staticcheck = true,
            gofumpt = false,
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
      }
    end,

    ['golangci_lint_ls'] = function()
      lspconfig.golangci_lint_ls.setup {
        filetypes = { 'go', 'gomod' },
        cmd = { vim.fn.expand('$HOME/.local/share/nvim/mason/bin/golangci-lint-langserver') },
        root_dir = lspconfig.util.root_pattern('go.work', 'go.mod', '.git', '.golangci.yml', '.golangci.yaml', '.golangci.toml', '.golangci.json'),
        init_options = {
          command = {
            vim.fn.expand('$HOME/.local/share/nvim/mason/bin/golangci-lint'),
            'run',
            '--enable-all',
            '--out-format', 'json',
            '--issues-exit-code=1',
            '--disable', 'deadcode,exhaustivestruct,forbidigo,funlen,gochecknoglobals,godox,golint,ifshort,interfacer,maligned,nonamedreturns,nosnakecase,scopelint,structcheck,varcheck,varnamelen,wsl'
          },
        }
      }
    end,

    ['elixirls'] = function()
      -- Currently configured by elixir-tools.nvim in plugins/init.lua
      -- lspconfig.elixirls.setup {
      --   settings = {
      --     elixirLS = {
      --       dialyzerEnabled = true,
      --       fetchDeps = true,
      --       incrementalDialyzer = true,
      --       suggestSpecs = true,
      --       enableTestLenses = true,
      --     },
      --   },
      -- }
    end
  },
})
require('mason-nvim-dap').setup({
  ensure_installed = {
    'bash',
    'codelldb',
    'cppdbg',
    'delve',
    'elixir',
    'javadbg',
    'javatest',
    'js',
    'kotlin',
    'python',
  },

  -- See mason-nvim-dap advanced configuration for an example on how to override default handlers/adapter setup
  handlers = {}
})

local cmp = require('cmp')
local cmp_select = { behaviour = cmp.SelectBehavior.Select }
local cmp_mappings = lsp_zero.defaults.cmp_mappings({
  ['<C-Space>'] = cmp.mapping.complete(),
  ['<C-k>'] = cmp.mapping.select_prev_item(cmp_select),
  ['<C-j>'] = cmp.mapping.select_next_item(cmp_select),
  ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
  ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),

  ['<C-y>'] = cmp.mapping.confirm({ select = true }),


  ['<C-e>'] = cmp.mapping.close(),
  ['<C-u>'] = cmp.mapping.scroll_docs(-4),
  ['<C-d>'] = cmp.mapping.scroll_docs(4),
  ['<CR>'] = cmp.mapping.confirm({
    behavior = cmp.ConfirmBehavior.Replace,
    select = false,
  }),

  -- ['<Tab>'] = cmp.mapping(function(fallback)
  --   if cmp.visible() then
  --     cmp.select_next_item({ behavior = cmp.SelectBehavior.Insert })
  --   elseif luasnip.expand_or_jumpable() then
  --     luasnip.expand_or_jump()
  --   else
  --     fallback()
  --   end
  -- end, { 'i', 's' }),
  --
  -- ['<S-Tab>'] = cmp.mapping(function(fallback)
  --   if cmp.visible() then
  --     cmp.select_prev_item()
  --   elseif luasnip.jumpable(-1) then
  --     luasnip.jump(-1)
  --   else
  --     fallback()
  --   end
  -- end, { 'i', 's' }),
})

cmp.setup({
  window = {},
  mapping = cmp_mappings,
  sources = {
    { name = 'buffer' },
    { name = 'luasnip' },
    { name = 'nvim_lsp' },
    { name = 'path' },
  },
})

lsp_zero.set_preferences({
  sign_icons = {}
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

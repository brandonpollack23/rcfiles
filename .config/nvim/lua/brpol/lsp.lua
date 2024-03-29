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
    'eslint',
    'gopls',
    'jsonls',
    'lua_ls',
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
              -- library = {
              --   vim.env.VIMRUNTIME
              --   -- Depending on the usage, you might want to add additional paths here.
              --   -- "${3rd}/luv/library"
              --   -- "${3rd}/busted/library",
              -- }
              -- or pull in all of 'runtimepath'. NOTE: this is a lot slower
              library = {
                vim.api.nvim_get_runtime_file('', true),
                '${3rd}/luassert/library',
                '${3rd}/luv/library',
                '${3rd}/busted/library',
              }
            },
          })
        end,
        settings = {
          Lua = {}
        }
      }
    end,
  },
})

local cmp = require('cmp')
local cmp_select = { behaviour = cmp.SelectBehavior.Select }
local cmp_mappings = lsp_zero.defaults.cmp_mappings({
  ['C-k'] = cmp.mapping.select_prev_item(cmp_select),
  ['C-j'] = cmp.mapping.select_next_item(cmp_select),
  ['C-p'] = cmp.mapping.select_prev_item(cmp_select),
  ['C-n'] = cmp.mapping.select_next_item(cmp_select),

  ['C-y'] = cmp.mapping.confirm({ select = true }),
  ['C-e'] = cmp.mapping.abort(),

  ['C-Space'] = cmp.mapping.complete(),
})
cmp.setup({
  window = {},
  mapping = cmp.mapping.preset.insert(cmp_mappings)
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
      },
    },
    { buffer = bufnr, noremap = true, prefix = '<leader>' }
  )

  vim.keymap.set('n', '<C-q>', vim.lsp.buf.hover, { noremap = true })
  vim.keymap.set('i', '<C-q>', vim.lsp.buf.hover, { noremap = true })
  vim.keymap.set('n', '<C-.>', vim.lsp.buf.code_action, { noremap = true })
  vim.keymap.set('i', '<C-.>', vim.lsp.buf.code_action, { noremap = true })
  vim.keymap.set('i', '<C-h>', function() vim.lsp.buf.signature_help() end, { remap = false, buffer = bufnr })
  vim.keymap.set('i', '<C-P>', function() vim.lsp.buf.signature_help() end, { remap = false, buffer = bufnr })
end)

lsp_zero.setup()

-- Diagnostics
vim.diagnostic.config({
  virtual_text = { severity = { min = vim.diagnostic.severity.INFO } },
  underline = true,
})

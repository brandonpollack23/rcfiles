local wk = require('which-key')
local vscode_theme = require('brpol.vscode_theme')
local telescopeBuiltin = require('telescope.builtin')
local telescopeExtensions = require('telescope').extensions

-- TODO change things to be in their respective on attach for plugins?

-- https://github.com/folke/which-key.nvim?tab=readme-ov-file#%EF%B8%8F-mappings
wk.register({
    d = {
      name = 'File Tree Operations',
      d = { '<cmd>NvimTreeToggle<cr>', 'File Tree' },
      f = { '<cmd>NvimTreeFindFile<cr>', 'File Tree (current file)' },
    },
    f = {
      name = 'Find/File/Search/Select Operations',
      f = { '<cmd>Telescope find_files<cr>', 'Find File' },
      g = { '<cmd>Telescope live_grep<cr>', 'Live Grep' },
      G = { function() telescopeBuiltin.grep_string({ search = vim.fn.input('Grep > ') }) end, 'Grep Files' },
      b = { '<cmd>Telescope buffers<cr>', 'Search Buffers' },
      h = { '<cmd>Telescope help_tags<cr>', 'Search Help' },
      p = { telescopeExtensions.smart_open.smart_open, 'Smart open (FULL)' },
      r = { ':Telescope lsp_references<cr>', 'LSP References' },
      s = { ':Telescope lsp_dynamic_workspace_symbols<cr>', 'LSP References' },
      S = { ':Telescope luasnip<cr>', 'Search snippets' }
    },
    k = {
      name = 'Colors',
      m = { vscode_theme.toggleDarkMode, 'Toggle Dark Mode' }
    },
    -- quick replace word
    s = { [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], 'Replace word in file' },
    ['?'] = {
      name = 'Show Mappings (WhichKey)',
      n = { ":WhichKey '' n<cr>", 'normal mode' },
      v = { ":WhichKey '' v<cr>", 'visual mode' },
      i = { ":WhichKey '' i<cr>", 'insert mode' },
    },
    y = { '<\"+y', 'yank into system clipboard' },
    Y = { '<\"+Y', 'yank line into system clipboard' },
  },
  { prefix = '<leader>' }
)

wk.register({
    J = { 'mzJ`z', 'join lines (preserve cursor)' },
    n = { 'nzzzv', 'next search result' },
    N = { 'Nzzzv', 'previous search result' },
  },
  { mode = 'n' }
)

wk.register({
    J = { ":move '>+1<CR>gv=gv", 'Move Selection Down' },
    K = { ":move '<-2<CR>gv=gv", 'Move Selection Up' },
  },
  { mode = 'v' }
)

wk.register({
    y = { '<\"+y', 'yank into system clipboard' },
  },
  { mode = 'v', prefix = '<leader>' }
)

wk.register({
    p = { '\"_dP', 'paste preserving default register' }
  },
  -- x is yank/cut mode
  { mode = 'x', prefix = '<leader>' }
)

wk.register({
  v = {
    P = { ':OutputPanel<cr>', 'Toggle LSP Output Panel' },
  }
}, { prefix = '<leader>' })

-- Return to normal mode from insert mode
vim.o.timeoutlen = 500 -- set timeout length so I can type literal jj faster
vim.keymap.set('i', 'jj', '<Esc>', { noremap = true })

-- Disable capital Q it is annoying and I don't understand it
vim.keymap.set('n', 'Q', '<nop>')

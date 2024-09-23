local wk = require('which-key')
local vscode_theme = require('brpol.vscode_theme')
local telescopeBuiltin = require('telescope.builtin')
local telescopeExtensions = require('telescope').extensions

-- TODO change things to be in their respective on attach for plugins?

-- https://github.com/folke/which-key.nvim?tab=readme-ov-file#%EF%B8%8F-mappings
wk.register({
    f = {
      name = 'Find/File/Search/Select Operations',
      ['<Space>'] = { '<cmd>Telescope resume<cr>', 'Registers' },
      t = { '<cmd>Telescope<cr>', 'Telescope' },

      f = { '<cmd>Telescope find_files<cr>', 'Find File' },
      g = { '<cmd>Telescope live_grep<cr>', 'Live Grep' },
      G = { function()
        local d = vim.fn.input('Grep dir> ', vim.fn.expand('%:p'), 'dir')
        telescopeBuiltin.live_grep({ cwd = d })
      end, 'Live grep from directory' },
      b = { '<cmd>Telescope buffers<cr>', 'Search Buffers' },
      c = { '<cmd>Telescope commands<cr>', 'Search commands' },
      h = { '<cmd>Telescope help_tags<cr>', 'Search Help' },
      p = { telescopeExtensions.smart_open.smart_open, 'Smart open (FULL)' },
      r = { ':Telescope lsp_references<cr>', 'LSP References' },
      k = { ':Telescope keymaps<cr>', 'Telescope keymap' },
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
    Q = {
      name = 'Profiling and debugging vim itself',
      s = { function()
        local log = vim.fn.expand('$HOME/tmp/profile.log')
        require('plenary.profile').start(log, { flame = true })
        vim.notify('Started profiling to ' ..
          log .. '\nStop with <leader>QS and use inferno-flamegraph to turn into a flamegraph')
      end, 'Start Profiling' },
      S = { function()
        require('plenary.profile').stop()
        vim.notify('Stopped profiling')
      end, 'Stop Profiling' },
    },
    ['%'] = { function()
      vim.cmd('let @+ = expand("%:p")')
      vim.notify(vim.fn.expand('%:p'))
    end, 'Show full path to file and copy to system clipboard'
    }
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

-- Return to normal mode from insert mode
vim.o.timeoutlen = 500 -- set timeout length so I can type literal jj faster
vim.keymap.set('i', 'jj', '<Esc>', { noremap = true })

-- Disable capital Q it is annoying and I don't understand it
vim.keymap.set('n', 'Q', '<nop>')

-- Setup <Tab> and <S-Tab> to work with luasnip and copilot
local luasnip = require('luasnip')
local suggestion = require('copilot.suggestion')
local cmp = require('cmp')

local function tab_complete()
  -- convert suggstion.is_visible() to a string to see if it is true or false
  if luasnip.expand_or_jumpable() then
    return luasnip.jump(1)
  elseif suggestion.is_visible() then
    -- Dismiss cmp suggestion
    cmp.close()
    return suggestion.accept()
  end
end

local function shift_tab_complete()
  if luasnip.jumpable(-1) then
    return luasnip.jump(-1)
  end
end

vim.keymap.set({ 'i', 's' }, '<Tab>', tab_complete, { silent = true })
vim.keymap.set({ 'i', 's' }, '<S-Tab>', shift_tab_complete, { silent = true })

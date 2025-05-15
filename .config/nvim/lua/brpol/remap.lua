local wk = require('which-key')
local vscode_theme = require('brpol.vscode_theme')
local telescopeBuiltin = require('telescope.builtin')
local telescopeExtensions = require('telescope').extensions

-- TODO change things to be in their respective on attach for plugins?

-- Leader prefixed keybindings
wk.add({
  -- Find/File operations group
  { "<leader>f", group = "Find/File/Search/Select Operations" },
  { "<leader>f<Space>", "<cmd>Telescope resume<cr>", desc = "Registers" },
  { "<leader>ft", "<cmd>Telescope<cr>", desc = "Telescope" },
  { "<leader>ff", function() telescopeBuiltin.find_files({ follow = true }) end, desc = "Find File" },
  { "<leader>fg", "<cmd>Telescope live_grep_args<cr>", desc = "Live Grep" },
  { "<leader>fG", function()
    local d = vim.fn.input('Grep dir> ', vim.fn.expand('%:p'), 'dir')
    telescopeBuiltin.live_grep({ cwd = d })
  end, desc = "Live grep from directory" },
  { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Search Buffers" },
  { "<leader>fc", "<cmd>Telescope commands<cr>", desc = "Search commands" },
  { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Search Help" },
  { "<leader>fp", function() telescopeExtensions.smart_open.smart_open({ cwd_only = true }) end, desc = "Smart open (no symlink)" },
  { "<leader>fP", telescopeExtensions.smart_open.smart_open, desc = "Smart open (FULL)" },
  { "<leader>fr", ":Telescope lsp_references<cr>", desc = "LSP References" },
  { "<leader>fk", ":Telescope keymaps<cr>", desc = "Telescope keymap" },
  { "<leader>fs", ":Telescope lsp_dynamic_workspace_symbols<cr>", desc = "LSP References" },
  { "<leader>fS", ":Telescope luasnip<cr>", desc = "Search snippets" },

  -- Git operations
  { "<leader>gf", "<cmd>Telescope git_status<cr>", desc = "Git Changed Files" },
  { "<leader>gl", "<cmd>Telescope git_commits<cr>", desc = "Git Directory Log" },
  { "<leader>gL", "<cmd>Telescope git_bcommits<cr>", desc = "Git Buffer Log" },
  { "<leader>gB", "<cmd>Telescope git_branches<cr>", desc = "Git Buffer Log" },

  -- Colors
  { "<leader>k", group = "Colors" },
  { "<leader>km", vscode_theme.toggleDarkMode, desc = "Toggle Dark Mode" },

  -- Show Mappings (WhichKey)
  { "<leader>?", group = "Show Mappings (WhichKey)" },
  { "<leader>?n", ":WhichKey '' n<cr>", desc = "normal mode" },
  { "<leader>?v", ":WhichKey '' v<cr>", desc = "visual mode" },
  { "<leader>?i", ":WhichKey '' i<cr>", desc = "insert mode" },

  -- Clipboard operations
  { "<leader>y", '<\"+y', desc = "yank into system clipboard" },
  { "<leader>Y", '<\"+y', desc = "yank line into system clipboard" },

  -- Profiling and debugging vim itself
  { "<leader>Q", group = "Profiling and debugging vim itself" },
  { "<leader>Qs", function()
    local log = vim.fn.expand('$HOME/tmp/profile.log')
    require('plenary.profile').start(log, { flame = true })
    vim.notify('Started profiling to ' ..
      log .. '\nStop with <leader>QS and use inferno-flamegraph to turn into a flamegraph') -- https://github.com/nvim-lua/plenary.nvim?tab=readme-ov-file#plenaryprofile
  end, desc = "Start Profiling" },
  { "<leader>QS", function()
    require('plenary.profile').stop()
    vim.notify('Stopped profiling')
  end, desc = "Stop Profiling" },

  -- Path operations
  { "<leader>%", function()
    vim.cmd('let @+ = expand("%:p")')
    vim.notify(vim.fn.expand('%:p'))
  end, desc = "Show full path to file and copy to system clipboard" },
})

-- Normal mode mappings
wk.add({
  { "J", "mzJ`z", desc = "join lines (preserve cursor)" },
  { "n", "nzzzv", desc = "next search result" },
  { "N", "Nzzzv", desc = "previous search result" },
  { "zn", ":normal! ]s<cr>", desc = "Next Misspelled Word" },
  { "zN", ":normal! [s<cr>", desc = "Previous Misspelled Word" },
})

-- Visual mode mappings
wk.add({
  { "J", ":move '>+1<CR>gv=gv", desc = "Move Selection Down", mode = "v" },
  { "K", ":move '<-2<CR>gv=gv", desc = "Move Selection Up", mode = "v" },
  { "<leader>y", '"+y', desc = "yank into system clipboard", mode = "v" },
})

-- Visual-block mode mappings (x mode)
wk.add({
  { "<leader>p", '\"_dP', desc = "paste preserving default register", mode = "x" },
})

-- Return to normal mode from insert mode
vim.o.timeoutlen = 500 -- set timeout length so I can type literal jj faster
vim.keymap.set('i', 'jj', '<Esc>', { noremap = true })

-- Disable capital Q it is annoying and I don't understand it
vim.keymap.set('n', 'Q', '<nop>')

-- Setup <Tab> and <S-Tab> to work with luasnip and copilot
-- local luasnip = require('luasnip')
-- local suggestion = require('copilot.suggestion')
-- local cmp = require('cmp')
--
-- local function tab_complete()
--   -- convert suggstion.is_visible() to a string to see if it is true or false
--   if luasnip.expand_or_jumpable() then
--     return luasnip.jump(1)
--   elseif suggestion.is_visible() then
--     -- Dismiss cmp suggestion
--     cmp.close()
--     return suggestion.accept()
--   else
--     vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Tab>', true, false, true), 'n', false)
--   end
-- end
--
-- local function shift_tab_complete()
--   if luasnip.jumpable(-1) then
--     return luasnip.jump(-1)
--   end
-- end
--
-- vim.keymap.set({ 'i', 's' }, '<Tab>', tab_complete, { silent = true })
-- vim.keymap.set({ 'i', 's' }, '<S-Tab>', shift_tab_complete, { silent = true })
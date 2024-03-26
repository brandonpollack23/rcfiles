local wk = require("which-key")
local vscode_theme = require("brpol.vscode_theme")
local telescopeBuiltin = require('telescope.builtin')
local telescopeExtensions = require('telescope').extensions

-- https://github.com/folke/which-key.nvim?tab=readme-ov-file#%EF%B8%8F-mappings
wk.register({
  d = {
    name = "File Tree Operations",
    d = { "<cmd>NvimTreeToggle<cr>", "File Tree" },
    f = { "<cmd>NvimTreeFindFile<cr>", "File Tree (current file)" },
  },
  f = {
    name = "File Operations",
    f = { "<cmd>Telescope find_files<cr>", "Find File" },
    g = { "<cmd>Telescope live_grep<cr>", "Live Grep" },
    s = { function() telescopeBuiltin.grep_string({ search = vim.fn.input("Grep > ") }) end, "Grep Files" },
    b = { "<cmd>Telescope buffers<cr>", "Search Buffers" },
    h = { "<cmd>Telescope help_tags<cr>", "Search Help" },
    p = { telescopeExtensions.smart_open.smart_open, "Smart open (FULL)" },
  },
  p = {
    name = "Default Vim Functions",
  },
  -- Create/delete a tab
  t = {  "<cmd>tabnew<cr>" ,"Tab Open" },
  w = {  "<cmd>tabclose<cr>" ,"Tab Open" },
  k = {
    name = "Colors",
    m = { vscode_theme.toggleDarkMode, "Toggle Dark Mode" }
  }
},
  { prefix = "<leader>" }
)

-- Return to normal mode from insert mode
vim.o.timeoutlen = 500 -- set timeout length so I can type literal jj faster
vim.keymap.set("i", "jj", "<Esc>", {noremap = true})

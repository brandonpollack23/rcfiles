local wk = require("which-key")

-- https://github.com/folke/which-key.nvim?tab=readme-ov-file#%EF%B8%8F-mappings
wk.register({
  d = {
    name = "File Tree Operations",
    d = { "<cmd>NvimTreeToggle<cr>", "File Tree" },
    f = { "<cmd>NvimTreeFindFile<cr>", "File Tree (current file)" },
  },
  f = {
    name = "File Operations",
    f = { "<cmd>Telescope find files<cr>", "Find File" },
  },
  p = {
    name = "Default Vim Functions",
  },
  -- Create/delete a tab
  t = {  "<cmd>tabnew<cr>" ,"Tab Open" },
  w = {  "<cmd>tabclose<cr>" ,"Tab Open" },
  },
  { prefix = "<leader>" }
)

-- Return to normal mode from insert mode
vim.o.timeoutlen = 500 -- set timeout length so I can type literal jj faster
vim.keymap.set("i", "jj", "<Esc>", {noremap = true})

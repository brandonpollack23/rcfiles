local wk = require("which-key")

vim.g.mapleader = ","

-- https://github.com/folke/which-key.nvim?tab=readme-ov-file#%EF%B8%8F-mappings
wk.register({
    f = {
      name = "File Operations",
      f = { "<cmd>Telescope find files<cr>", "Find File" },
      t = { "<cmd>Neotree toggle<cr>", "File Tree" },
    },
    p = {
      name = "Default Vim Functions",
      v = { "<cmd>Ex<cr>", "Vim File Browser (netrw)" },
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

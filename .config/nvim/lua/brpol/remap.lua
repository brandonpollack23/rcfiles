vim.g.mapleader = ","

vim.keymap.set("n", "<leader>pv", vim.cmd.Ex) -- Return to nvim's default file explorer
vim.keymap.set("n", "<leader>h", vim.cmd.noh) -- keybind to turn off search highlight

-- Return to normal mode from insert mode
vim.o.timeoutlen = 500 -- set timeout length so I can type literal jj faster
vim.keymap.set("i", "jj", "<Esc>", {noremap = true})

-- Create/delete a tab
vim.keymap.set("n", "<leader>t", vim.cmd.tabnew)
vim.keymap.set("n", "<leader>w", vim.cmd.tabclose)

-- TODO
-- LSP 
  -- trigger and accept with ctrl space
  -- autoformatting
  -- undefined global "vim"
  -- remove gutter icons, add squigles instead
  -- quick fix
  -- ctrl q for info about variable/type
  -- ctrl shift p for parameter info

-- IF bufferline doesnt work: telescope select tab instead of replacing

-- TODO plugins
  -- jump to window with easymotion
  -- a git plugin https://github.com/NeogitOrg/neogit
  -- popup terminal like vscode https://www.reddit.com/r/neovim/comments/kbwb0n/neovim_terminal_like_vscode/
  -- copilot
  -- file outline (function list etc)
  -- harpoon
  -- debugging files
  -- undotree
  -- commenter
  -- autoformat on save
  -- todo highlighting
-- Go through old vimrc to see if im missing anything

vim.g.mapleader = ","

-- Package manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup("plugins")

-- Key remaps
require("brpol.remap")

-- Individual Plugin Setup

require("brpol.vscode_theme")
require("brpol.hop_easymotion")
require("brpol.treesitter")
require("brpol.nvim-tree")
require("brpol.lsp")
require("brpol.telescope")
require("brpol.lualine")

-- Global options
-- Disable netrw (default file picker) at startup
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Enable 24 bit color
vim.opt.termguicolors = true

vim.o.number = true
vim.o.relativenumber = true
vim.o.backupdir = vim.fn.expand("$HOME/.vim/backupdir") -- Backup and swap dirs
vim.o.directory = vim.fn.expand("$HOME/.vim/swapdir")
vim.o.ignorecase = true -- ignore case in searches
vim.cmd('syntax enable')
vim.opt.encoding = "utf-8"
vim.opt.hlsearch = false

-- Used for swapdir writing and hover in normal mode like for previews in tree
vim.o.updatetime = 100

-- Make tab completion work like bash but with a list if you press tab again
vim.o.wildmode = "longest:full,full"
vim.o.wildmenu = true
vim.o.wildignorecase = true

-- Tab options
vim.o.expandtab = true
vim.o.shiftwidth = 2
vim.o.softtabstop = 2
vim.cmd('filetype indent on')
vim.cmd('filetype plugin on')
vim.o.smartindent = true

-- New windows always focused
vim.api.nvim_create_autocmd("WinNew", {
  pattern = "*",
  callback = function()
    vim.cmd('wincmd p')
  end,
})

-- Make scrolling always centered and have some offset
vim.keymap.set("n", "<C-u>", "<C-u>zz", {noremap = true})
vim.keymap.set("n", "<C-d>", "<C-d>zz", {noremap = true})
vim.o.scrolloff = 8

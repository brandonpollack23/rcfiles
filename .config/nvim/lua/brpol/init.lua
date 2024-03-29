-- TODO:
-- trigger and accept with ctrl space
-- quick fix
-- ctrl q for info about variable/type
-- ctrl shift p for parameter info

-- Lualine lsp progress https://github.com/linrongbin16/lsp-progress.nvim
-- Recursively open in nvim tree https://github.com/nvim-tree/nvim-tree.lua/pull/1292

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

vim.g.mapleader = ','

if vim.fn.has('win32') == 1 or vim.fn.has('win64') == 1 then
  require('brpol.windows')
end

-- Package manager
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup('plugins')

-- Individual Plugin Setup
require('brpol.vscode_theme')
require('brpol.hop_easymotion')
require('brpol.treesitter')
require('brpol.nvim-tree')
require('brpol.lsp')
require('brpol.telescope')
require('Comment').setup()

-- Key remaps
require('brpol.remap')

-- Global options
-- Disable netrw (default file picker) at startup
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Enable 24 bit color
vim.opt.termguicolors = true

vim.o.number = true
vim.o.relativenumber = true
vim.o.backupdir = vim.fn.expand('$HOME/.vim/backupdir') -- Backup and swap dirs
vim.o.directory = vim.fn.expand('$HOME/.vim/swapdir')
vim.o.ignorecase = true                                 -- ignore case in searches
vim.cmd('syntax enable')
vim.opt.encoding = 'utf-8'
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.colorcolumn = '100'

-- Save undos to a file
vim.opt.undodir = os.getenv('HOME') .. '/.vim/undodir'
vim.opt.undofile = true

-- Used for swapdir writing and hover in normal mode like for previews in tree
vim.o.updatetime = 50

-- Make tab completion work like bash but with a list if you press tab again
vim.o.wildmode = 'longest:full,full'
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
vim.api.nvim_create_autocmd('WinNew', {
  pattern = '*',
  callback = function()
    vim.cmd('wincmd p')
  end,
})

-- Make scrolling always centered and have some offset
vim.keymap.set('n', '<C-u>', '<C-u>zz', { noremap = true })
vim.keymap.set('n', '<C-d>', '<C-d>zz', { noremap = true })
vim.o.scrolloff = 8

-- WSL Stuff
local function is_wsl()
  -- Attempt to identify WSL by checking for the existence of a specific file or environment variable
  -- This checks for the presence of "/proc/version" containing "Microsoft" or "WSL"
  local proc_version = vim.fn.readfile('/proc/version')
  if string.find(table.concat(proc_version), 'Microsoft') or string.find(table.concat(proc_version), 'WSL') then
    return true
  end
  return false
end

local function on_yank()
  -- Check if we're in WSL and if the yank was into the '+' register
  if is_wsl() and vim.v.event.regname == '+' then
    -- Use the '+' register content and write to clip.exe
    local content = vim.fn.getreg('+')
    vim.fn.system('clip.exe', content)
  end
end

-- Set up the autocmd for the TextYankPost event
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = on_yank
})

-- Command to execute current buffer
local function execute_current_buffer()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local code = table.concat(lines, '\n')
  load(code)()
end

require('which-key').register({
  l = { execute_current_buffer, 'Source current buffer' },
}, { prefix = '<leader>' })

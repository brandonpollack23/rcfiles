-- TODO:
-- undotree
-- todo highlighting

-- Tips
-- :help slow-startup if its slow
-- :help trojan-horse to learn about exrc

vim.g.mapleader = ','
vim.g.maplocalleader = '<'

-- Setup neovide gui preferences
vim.g.neovide_cursor_animation_length = 0.0
vim.g.neovide_cursor_trail_size = 0.0
vim.g.neovide_scroll_animation_length = 0.0

-- set neovim python env to use ~/.config/nvim/.venv
-- First if the venv does not exist, create it:
if not vim.loop.fs_stat(os.getenv('HOME') .. '/.config/nvim/.venv') then
  -- Notify the user:
  vim.notify('Creating virtual environment for python plugins in nvim and instally necessary deps', vim.log.levels.INFO)
  os.execute('uv venv ' .. os.getenv('HOME') .. '/.config/nvim/.venv')

  -- Then install the required packages for image.nvim and jupyter:
  os.execute('uv pip install pynvim jupyter_client cairosvg pnglatex plotly pyperclip --python=$HOME/.config/nvim/.venv/bin/python')
end
vim.g.python3_host_prog = os.getenv('HOME') .. '/.config/nvim/.venv/bin/python3'

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

vim.api.nvim_set_keymap('n', '<C-c><C-c>', '<Cmd>call firenvim#focus_page()<CR>', {})

require('lazy').setup({
  rocks = {
    enabled = true,
    hererocks = true,
  },
  spec = {
    import = 'plugins'
  }
})

-- Individual Plugin Setup
require('brpol.vscode_theme')

-- Custom commands
require('brpol.commands')

-- Key remaps
require('brpol.remap')

-- Command to execute current buffer in lua
-- TODO organize this under commands and remap>
local function execute_current_buffer()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local code = table.concat(lines, '\n')
  load(code)()
end

require('which-key').register({
  l = { execute_current_buffer, 'Source current buffer' },
}, { prefix = '<leader>' })

-- Global options
-- Enable project local .nvim.lua, .exrc, or .nvimrc
vim.o.exrc = true
-- Disable netrw (default file picker) at startup
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Enable 24 bit color
vim.opt.termguicolors = true

vim.o.spell = true
-- disable spell on terminals
vim.api.nvim_create_autocmd('TermOpen', {
  pattern = '*',
  callback = function()
    vim.opt_local.spell = false
  end,
})
-- Set spell cap to not highlight
vim.o.spellcapcheck = ''
vim.o.spelloptions = 'camel'

vim.o.number = true
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

-- Language overrides
vim.g.python_recommended_style = 0

-- Tab options
-- disable rust recomended style and use my own and rustfmt
vim.g.rust_recommended_style = false
vim.o.expandtab = true
vim.o.shiftwidth = 2
vim.o.softtabstop = 2
vim.o.tabstop = 2
vim.cmd('filetype indent on')
vim.cmd('filetype plugin on')
vim.o.smartindent = true

-- Make scrolling always centered and have some offset
vim.o.scrolloff = 4

-- WSL Stuff
local function is_wsl()
  -- Attempt to identify WSL by checking for the existence of a specific file or environment variable
  -- This checks for the presence of "/proc/version" containing "Microsoft" or "WSL"
  local ok, proc_version = pcall(vim.fn.readfile, '/proc/version')
  if not ok then
    return false
  end

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

-- TODO REMOVE RUST WORKAROUND ON ARCH
for _, method in ipairs({ 'textDocument/diagnostic', 'workspace/diagnostic' }) do
  local default_diagnostic_handler = vim.lsp.handlers[method]
  vim.lsp.handlers[method] = function(err, result, context, config)
    if err ~= nil and err.code == -32802 then
      return
    end
    return default_diagnostic_handler(err, result, context, config)
  end
end

if is_wsl() then
  vim.g.clipboard = {
    name = 'wslclip',
    copy = {
      ['+'] = 'clip.exe',
      ['*'] = 'clip.exe',
    },
    paste = {
      ['+'] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
      ['*'] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
    },
    cache_enabled = 0,
  }
end

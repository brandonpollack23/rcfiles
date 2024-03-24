-- TODO fixes
-- move vscode and hop to after directory

-- TODO plugins
-- copilot
-- todo highlighting

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

require("lazy").setup({
  {"Mofiqul/vscode.nvim"},
  {
    'smoka7/hop.nvim', -- EasyMotion
    version = "*",
    opts = {},
  },
  {
    "kylechui/nvim-surround",
    version = "*", -- Use for stability; omit to use `main` branch for the latest features
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup({
        -- Configuration here, or leave empty to use defaults
      })
    end
  },
  -- Fuzzy finder (file finder etc), see "after" config directory for bindings, 
  -- ctrl-p from vscode is equivalent and for non git repos there is <leader>ff
  {"nvim-telescope/telescope.nvim", dependencies =  {'nvim-lua/plenary.nvim'} }, 
})

-- Key remaps
require("brpol.remap")

-- Individual Plugin Setup

require("brpol.vscode_theme")
require("brpol.hop_easymotion")

-- telescope (fuzzy finder pickers)
local telescopeConfig = require("telescope.config")
local vimgrep_arguments = { unpack(telescopeConfig.values.vimgrep_arguments) }
table.insert(vimgrep_arguments, "--hidden")
-- I don't want to search in the `.git` directory.
table.insert(vimgrep_arguments, "--glob")
table.insert(vimgrep_arguments, "!**/.git/*")
require("telescope").setup({
  defaults = {
    vimgrep_arguments = vimgrep_arguments
  },
  pickers = {
    find_files = {
      -- `hidden = true` will still show the inside of `.git/` as it's not `.gitignore`d.
      find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
    },
  },
})
require("brpol.telescope")

-- Global options
vim.o.number = true
vim.o.backupdir = vim.fn.expand("$HOME/.vim/backupdir") -- Backup and swap dirs
vim.o.directory = vim.fn.expand("$HOME/.vim/swapdir")
vim.o.ignorecase = true -- ignore case in searches
vim.cmd('syntax enable')
vim.opt.encoding = "utf-8"
-- vim.o.wildmode = "longest" -- tab completion that doesnt suck

-- Tab options
vim.o.expandtab = true
vim.o.shiftwidth = 2
vim.o.softtabstop = 2
vim.cmd('filetype indent on')
vim.cmd('filetype plugin on')
vim.o.smartindent = true

-- New tabs open with vertical splits
vim.api.nvim_create_autocmd("FileType", {
  pattern = "help",
  callback = function()
    -- Check if the current window is not already in a vertically split window
    if vim.fn.winwidth(0) > 80 then
      vim.cmd("wincmd L") -- Move the current window to the far right
      vim.cmd("vertical resize 80") -- Optionally resize the help window to a specific width
    else
      -- If the window is too narrow, just open help in the current window
      -- Alternatively, you can decide to split the window anyway or adjust it differently
    end
  end
})

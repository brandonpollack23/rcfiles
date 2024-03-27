local builtin = require('telescope.builtin')
local extensions = require('telescope').extensions

vim.keymap.set('n', '<C-p>', function() extensions.smart_open.smart_open({ cwd_only = true }) end, {})

-- Hack to make Ctrl-C work to close
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('user-telescope-picker', { clear = true }),
  pattern = { 'TelescopePrompt' },
  callback = function(event)
    vim.keymap.set('i', '<C-c>', function()
      require('telescope.actions').close(event.buf)
    end, { noremap = true, silent = true, buffer = event.buf })
  end,
})

local telescopeConfig = require("telescope.config")
local vimgrep_arguments = { unpack(telescopeConfig.values.vimgrep_arguments) }
table.insert(vimgrep_arguments, "--hidden")
-- I don't want to search in the `.git` directory.
table.insert(vimgrep_arguments, "--glob")
table.insert(vimgrep_arguments, "!**/.git/*")
require("telescope").setup({
  defaults = {
    vimgrep_arguments = vimgrep_arguments,
  },
  pickers = {
    find_files = {
      -- `hidden = true` will still show the inside of `.git/` as it's not `.gitignore`d.
      find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
    },
  },
  extensions = {
    smart_open = {
      show_scores = false,
      ignore_patterns = { "*.git/*" },
      -- Enable to use fzy, needs to be installed though
      match_algorithm = "fzy",
      disable_devicons = false,
      -- open_buffer_indicators = {previous = "👀", others = "🙈"},
    },
  }
})

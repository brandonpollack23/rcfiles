require('nvim-treesitter.configs').setup ({
  -- A list of parser names, or "all" https://github.com/nvim-treesitter/nvim-treesitter?tab=readme-ov-file#supported-languages
  ensure_installed = "all",

  -- Install parsers synchronously (only applied to `ensure_installed`)
  sync_install = false,

  -- Automatically install missing parsers when entering buffer
  -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
  auto_install = true,

  highlight = {
    enable = true,

    -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
    -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
    -- Using this option may slow down your editor, and you may see some duplicate highlights.
    -- Instead of true it can also be a list of languages
    additional_vim_regex_highlighting = false,
  },

  refactor = {
    highlight_definitions = {
      enable = true,
      clear_on_cursor_move = false, -- No need, update time is high enough
    },

    smart_rename = {
      enable = true,
      -- Assign keymaps to false to disable them, e.g. `smart_rename = false`.
      keymaps = {
        smart_rename = "grr",
      },
    },
  }
})

-- https://github.com/nvim-treesitter/nvim-treesitter-refactor/blob/master/doc/nvim-treesitter-refactor.txt#L145
-- vim.cmd('hi TSDefinition guibg=')
vim.cmd('hi TSDefinitionUsage guibg=#3A3A3A')

return {
  "Mofiqul/vscode.nvim",
  "EdenEast/nightfox.nvim",
  "navarasu/onedark.nvim",
  "sainnhe/sonokai",
  {
    "LazyVim/LazyVim",
    -- With `vim.g.omarchy_theme` on, theme.lua sets the colorscheme instead.
    opts = vim.g.omarchy_theme and {} or {
      colorscheme = "sonokai",
    },
  },
}

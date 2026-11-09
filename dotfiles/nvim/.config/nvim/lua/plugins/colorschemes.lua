return {
  "Mofiqul/vscode.nvim",
  "EdenEast/nightfox.nvim",
  "navarasu/onedark.nvim",
  {
    "sainnhe/sonokai",
    -- Omarchy's plugin/after/transparency.lua (outside this repo) clears
    -- Normal's background and more, so the terminal's colour, which follows
    -- the Omarchy theme, shows through instead of sonokai's. It is sourced
    -- with the other plugin scripts, after LazyVim has applied the
    -- colorscheme, so set it again on VimEnter, which comes after them all.
    -- Only when sonokai is ours: with `vim.g.omarchy_theme` on, transparency
    -- is part of following the Omarchy theme.
    init = function()
      if vim.g.omarchy_theme then
        return
      end
      vim.api.nvim_create_autocmd("VimEnter", {
        once = true,
        callback = function()
          if vim.g.colors_name == "sonokai" then
            vim.cmd.colorscheme("sonokai")
          end
        end,
      })
    end,
  },
  {
    "LazyVim/LazyVim",
    -- With `vim.g.omarchy_theme` on, theme.lua sets the colorscheme instead.
    opts = vim.g.omarchy_theme and {} or {
      colorscheme = "sonokai",
    },
  },
}

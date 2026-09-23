-- For Omarchy: follow the theme chosen with `omarchy theme set`.
--
-- Omarchy regenerates a LazyVim plugin spec at the path below on every theme
-- switch, and its own nvim ships this as a relative symlink at
-- lua/plugins/theme.lua. A symlink can't live in a stow package (the relative
-- target would resolve from the repo, not from ~/.config/nvim), so load the
-- file instead. Absent -- any machine that isn't Omarchy -- this is a no-op.
--
-- NOTE: the generated spec sets LazyVim's `colorscheme` opt, and so does
-- colorschemes.lua (sonokai). Both loading is ambiguous, so pick one: keep
-- sonokai and delete this file, or let Omarchy drive it and drop the
-- `colorscheme` opt from colorschemes.lua. See todo.md §1.

local generated = vim.fn.expand("~/.local/state/omarchy/current/theme/neovim.lua")

if (vim.uv or vim.loop).fs_stat(generated) then
  return dofile(generated)
end

return {}

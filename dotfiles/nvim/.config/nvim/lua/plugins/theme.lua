-- For Omarchy: follow the theme chosen with `omarchy theme set`.
--
-- Omarchy regenerates a LazyVim plugin spec at the path below on every theme
-- switch, and its own nvim ships this as a relative symlink at
-- lua/plugins/theme.lua. A symlink can't live in a stow package (the relative
-- target would resolve from the repo, not from ~/.config/nvim), so load the
-- file instead. Absent -- any machine that isn't Omarchy -- this is a no-op.
--
-- Only when `vim.g.omarchy_theme` is true (set in config/options.lua, which
-- LazyVim loads before this spec is read). Otherwise colorschemes.lua's
-- sonokai stays in charge.

local generated = vim.fn.expand("~/.local/state/omarchy/current/theme/neovim.lua")

if vim.g.omarchy_theme and (vim.uv or vim.loop).fs_stat(generated) then
  return dofile(generated)
end

return {}

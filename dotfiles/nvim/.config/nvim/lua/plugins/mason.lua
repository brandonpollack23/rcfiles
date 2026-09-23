-- Mason tools to always have installed, on top of whatever the LazyVim extras
-- pull in. opts_extend concatenates ensure_installed across specs without
-- deduplicating, and LazyVim's mason config calls install() on every entry
-- that isn't installed yet, so a tool listed twice (stylua, prettier, ...)
-- fails with "Package is already installing" on a fresh machine. This spec is
-- imported after LazyVim and its extras, so dedupe the merged list here.
local tools = {
  -- amber (server set up in languages.lua; no lspconfig mapping, so
  -- it has to be listed here to get installed)
  "amber-lsp",
  -- elixir
  "elixir-ls",
  "expert",
  -- lua
  "lua-language-server",
  "stylua",
  -- ts/js/css
  "vtsls",
  "prettier",
  "js-debug-adapter",
  "tailwindcss-language-server",
  -- json
  "json-lsp",
  -- shells
  "bash-language-server",
  "shellcheck",
  "shfmt",
  -- python
  "pyright",
  "ruff",
  "debugpy",
  -- docker
  "dockerfile-language-server",
  "docker-compose-language-service",
  "hadolint",
}

return {
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = LazyVim.dedup(vim.list_extend(opts.ensure_installed or {}, tools))
    end,
  },
}

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

-- Tools the extras list that we don't want: fantomas is the dotnet extra's
-- F# formatter, and that extra is here for C# only.
local skip = { fantomas = true }

return {
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      local merged = LazyVim.dedup(vim.list_extend(opts.ensure_installed or {}, tools))
      opts.ensure_installed = vim.tbl_filter(function(tool)
        return not skip[tool]
      end, merged)
    end,
  },
}

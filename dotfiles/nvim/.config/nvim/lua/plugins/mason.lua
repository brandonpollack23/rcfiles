-- Mason tools to always have installed, on top of whatever the LazyVim extras
-- pull in. mason.nvim declares opts_extend = { "ensure_installed" }, so this
-- list is appended to the defaults rather than replacing them.
return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
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
      },
    },
  },
}

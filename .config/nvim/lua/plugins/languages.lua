return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        elixirls = {
          autostart = false,
          mason = false,
          settings = {
            elixirLS = {
              -- Dialyzer is required for the Workspace Symbol index
              dialyzerEnabled = true,
              -- Allows ElixirLS to fetch/compile deps if needed
              fetchDeps = true,
            },
          },
        },
      },
    },
  },
}

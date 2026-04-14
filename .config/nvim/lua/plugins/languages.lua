vim.api.nvim_create_autocmd("FileType", {
  pattern = "prolog",
  once = true,
  callback = function()
    if vim.fn.executable("swipl") ~= 1 then
      vim.notify("Swipl not detected, have you installed swi prolog?", vim.log.levels.WARN)
      return
    end

    -- vim.fn.system("swipl -g 'use_module(library(lsp_server))' -g halt 2>&1")
    --
    -- if vim.v.shell_error ~= 0 then
    --   vim.notify("[prolog_ls] lsp_server pack not found. Run:\n  swipl pack install lsp_server", vim.log.levels.WARN)
    -- end
  end,
})

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      codelens = { enabled = true },
      servers = {
        prolog_ls = {
          -- nvim-lspconfig already knows the default cmd, but explicit is safer:
          cmd = {
            "swipl",
            "-g",
            "use_module(library(lsp_server)).",
            "-g",
            "lsp_server:main",
            "-t",
            "halt",
            "--",
            "stdio",
          },
          filetypes = { "prolog" },
          root_markers = { "pack.pl", ".git" },
        },
        tailwindcss = {
          root_markers = {
            "assets/tailwind.config.js",
            "tailwind.config.js",
            "tailwind.config.cjs",
            "tailwind.config.ts",
            "mix.exs",
            ".git",
          },
          filetypes = {
            "html",
            "css",
            "javascript",
            "javascriptreact",
            "typescript",
            "typescriptreact",
            "heex",
            "elixir",
            "eelixir",
          },
          init_options = {
            userLanguages = {
              heex = "html",
              elixir = "html",
              eelixir = "html",
            },
          },
        },
        elixirls = {
          mason = false,
          settings = {
            elixirLS = {
              -- Dialyzer is required for the Workspace Symbol index
              -- dialyzerEnabled = true,
              -- Allows ElixirLS to fetch/compile deps if needed
              fetchDeps = true,
              suggestSpecs = true,
            },
          },
        },
      },
    },
  },
  {
    "Neurarian/snacks-luasnip.nvim",
    dependencies = {
      "folke/snacks.nvim",
      "L3MON4D3/LuaSnip",
    },
    keys = {
      {
        "<leader>sL",
        function()
          require("snacks-luasnip").pick()
        end,
        desc = "Search LuaSnip Snippets",
      },
    },
  },
}

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
        -- nvim-lspconfig and mason-lspconfig have no entry for amber-lsp, so
        -- define it here; mason = false keeps LazyVim from looking one up.
        -- The binary still comes from Mason, via ensure_installed in mason.lua.
        amber_lsp = {
          mason = false,
          cmd = { "amber-lsp" },
          filetypes = { "amber" },
          root_markers = { "mise.toml", ".git" },
        },
        nixd = {
          -- Use the nixd already on PATH (/usr/bin/nixd) instead of Mason.
          mason = false,
          settings = {
            nixd = {
              nixpkgs = { expr = "import <nixpkgs> { }" },
              options = {
                nixos = {
                  expr = [[
                    let f = builtins.getFlake (toString ./.);
                        c = f.nixosConfigurations;
                    in c.${builtins.head (builtins.attrNames c)}.options
                  ]],
                },
              },
            },
          },
        },
        -- prolog = {
        --   -- nvim-lspconfig already knows the default cmd, but explicit is safer:
        --   cmd = {
        --     "swipl",
        --     "-g",
        --     "use_module(library(lsp_server)).",
        --     "-g",
        --     "lsp_server:main",
        --     "-t",
        --     "halt",
        --     "--",
        --     "stdio",
        --   },
        --   root_markers = { "pack.pl", ".git" },
        --   filetypes = { "prolog" },
        -- },
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
        -- Elixir goes through expert (installed in mason.lua) instead.
        elixirls = { enabled = false },
        -- The dotnet extra is here for C#; no F#.
        fsautocomplete = { enabled = false },
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
  -- hex completion for deps in elixir
  { "dbernheisel/hex-cmp" },
  {
    "amber-lang/amber-vim",
    init = function()
      -- amber-vim's ftdetect uses setfiletype, which loses to shebang detection
      -- (`#!/usr/bin/env -S sh -c 'exec amber run ...'` reads as sh).
      vim.filetype.add({ extension = { ab = "amber" } })
    end,
  },
}

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
        -- Erlang goes through ELP instead of the erlang extra's erlang_ls:
        -- erlang_ls is archived, and Mason builds it from source with rebar3,
        -- which fails on current OTP. ELP is a prebuilt binary.
        erlangls = { enabled = false },
        elp = {},
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
      -- (`#!/usr/bin/env -S amber run ...` names env, not amber).
      vim.filetype.add({ extension = { ab = "amber" } })
    end,
  },
  {
    "Julian/lean.nvim",
    opts = {
      goal_markers = {
        unsolved = " ⚒ ",
        accomplished = "🎉",
      },
    },
    init = function()
      -- lean.nvim links leanUnsolvedGoals to DiagnosticInfo and leaves
      -- leanGoalsAccomplished undefined. Colorschemes clear highlights, so set
      -- these on every switch, from whatever the new colorscheme defines.
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = function()
          vim.api.nvim_set_hl(0, "leanUnsolvedGoals", { link = "DiagnosticWarn" })
          -- DiffAdd's background alone, to keep the proof's syntax colors. Not a
          -- blend with Normal's: transparency.lua leaves Normal without a background.
          local diff_add = vim.api.nvim_get_hl(0, { name = "DiffAdd", link = false })
          vim.api.nvim_set_hl(0, "leanGoalsAccomplished", { bg = diff_add.bg })
        end,
      })
    end,
  },
}

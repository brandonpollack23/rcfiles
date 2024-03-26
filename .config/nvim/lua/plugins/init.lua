return {
  {"Mofiqul/vscode.nvim"},

  {
    'smoka7/hop.nvim', -- EasyMotion
    version = "*",
    opts = {},
  },

  {
    "kylechui/nvim-surround",
    version = "*", -- Use for stability; omit to use `main` branch for the latest features
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup({
        -- Configuration here, or leave empty to use defaults
      })
    end
  },

  -- Fuzzy finder (file finder etc), see "after" config directory for bindings, 
  -- ctrl-p from vscode is equivalent and for non git repos there is <leader>ff
  {"nvim-telescope/telescope.nvim", dependencies =  {'nvim-lua/plenary.nvim'} },
  {
    "danielfalk/smart-open.nvim",
    branch = "0.2.x",
    config = function()
      require("telescope").load_extension("smart_open")
    end,
    dependencies = {
      "kkharji/sqlite.lua",
      -- Only required if using match_algorithm fzf
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
      -- Optional.  If installed, native fzy will be used when match_algorithm is fzy
      { "nvim-telescope/telescope-fzy-native.nvim" },
    },
  },

  {
    "nvim-treesitter/nvim-treesitter", -- Better syntax highlighting etc
    build = function()
      require("nvim-treesitter.install").update({ with_sync = true })()
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-refactor",
    dependencies = "nvim-treesitter/nvim-treesitter"
  },

  -- modern NERDTree
  {
    "nvim-tree/nvim-tree.lua",
    version = "*",
    lazy = false,
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      {
        "JMarkin/nvim-tree.lua-float-preview",
        lazy = false,
        -- default
        opts = {
          -- Whether the float preview is enabled by default. When set to false, it has to be "toggled" on.
          toggled_on = true,
          -- wrap nvimtree commands
          wrap_nvimtree_commands = true,
          -- lines for scroll
          scroll_lines = 20,
          -- window config
          window = {
            style = "minimal",
            relative = "win",
            border = "rounded",
            wrap = false,
          },
          mapping = {
            -- scroll down float buffer
            down = { "<C-d>" },
            -- scroll up float buffer
            up = { "<C-e>", "<C-u>" },
            -- enable/disable float windows
            toggle = { "<C-x>" },
          },
          -- hooks if return false preview doesn't shown
          hooks = {
            pre_open = function(path)
              -- if file > 5 MB or not text -> not preview
              local size = require("float-preview.utils").get_size(path)
              if type(size) ~= "number" then
                return false
              end
              local is_text = require("float-preview.utils").is_text(path)
              return size < 5 and is_text
            end,
            post_open = function(bufnr)
              return true
            end,
          },
        },
      }
    },
    config = function()
      require("nvim-tree").setup {}
    end,
  },
  {
    "antosha417/nvim-lsp-file-operations",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-tree.lua",
    },
    config = function()
      require("lsp-file-operations").setup()
    end,
  },

  -- Pretty status line
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' }
  },

  {
    "folke/which-key.nvim", -- Helps remember keybindings
    event = "VeryLazy",
    init = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300
    end,
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    }
  },

  {
    'numToStr/Comment.nvim',
    opts = {
      -- add any options here
    },
    lazy = false,
  },

  -- LSP stuff
  --- Uncomment the two plugins below if you want to manage the language servers from neovim
  {'williamboman/mason.nvim'},
  {'williamboman/mason-lspconfig.nvim'},
  {'VonHeikemen/lsp-zero.nvim', branch = 'v3.x'},
  {'neovim/nvim-lspconfig'},
  {'hrsh7th/cmp-nvim-lsp'},
  {'hrsh7th/nvim-cmp'},
  {'L3MON4D3/LuaSnip'},
}

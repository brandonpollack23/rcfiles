return {
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    keys = {
      -- 0. disable s so replace still works
      { "s", mode = { "n", "x", "o" }, false },
      -- 1. Generic "Jump to anywhere" (The modern way)
      {
        "<leader><leader>s",
        mode = { "n", "x", "o" },
        function()
          require("flash").jump()
        end,
        desc = "Flash Jump",
      },
      -- 2. EasyMotion Style: Jump to Word (<Leader><Leader>w)
      {
        "<leader><leader>w",
        mode = { "n", "x", "o" },
        function()
          require("flash").jump({
            pattern = "\\<", -- match word boundaries only
            search = {
              mode = "search",
              max_length = 0,
            },
            label = { after = { 0, 0 } },
          })
        end,
        desc = "Jump to Word",
      },
      {
        "<leader><leader>b",
        mode = { "n", "x", "o" },
        function()
          require("flash").jump({
            pattern = "\\<", -- match word boundaries only
            search = {
              mode = "search",
              max_length = 0,
            },
            label = { after = { 0, 0 } },
            direction = "backward",
          })
        end,
        desc = "Jump to Word",
      },
      -- 3. EasyMotion Style: Jump to Line (<Leader><Leader>l)
      {
        "<leader><leader>j",
        mode = { "n", "x", "o" },
        function()
          require("flash").jump({
            search = { mode = "search", max_length = 0 },
            label = { after = { 0, 0 } },
            pattern = [[^\s*\zs\S\|^']],
          })
        end,
        desc = "Jump to Line",
      },
      {
        "<leader><leader>k",
        mode = { "n", "x", "o" },
        function()
          require("flash").jump({
            search = { mode = "search", max_length = 0 },
            label = { after = { 0, 0 } },
            pattern = [[^\s*\zs\S\|^']],
            direction = "backward",
          })
        end,
        desc = "Jump to Line",
      },
    },
  },
  {
    "folke/snacks.nvim",
    keys = {
      -- unlock this for other random stuff
      { "<leader><leader>", false },
    },
  },
}

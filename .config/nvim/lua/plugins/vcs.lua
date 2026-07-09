return {
  "rafikdraoui/jj-diffconflicts",
  {
    "gitsigns.nvim",
    opts = {
      current_line_blame = true,
      current_line_blame_formatter = "<abbrev_sha> <author>, <author_time:%R> - <summary>",
    },
  },
  --   remember to set workspace root with
  --     require("jj-signs").setup({
  --   jj_repo = "/path/to/workspace",
  -- })
  -- in .nvim.lua of your workspaces
  {
    "bnrobinson93/jj-signs.nvim",
    event = "LazyFile",
    opts = {},
  },
  -- diff view for merge conflicts
  {
    "dlyongemallo/diffview-plus.nvim",
    version = "*",
    -- optional: lazy-load on command
    -- cmd = {
    --     "DiffviewOpen",
    --     "DiffviewToggle",
    --     "DiffviewFileHistory",
    --     "DiffviewDiffFiles",
    --     "DiffviewLog",
    -- },
    keys = {
      -- Toggle diffview open/close
      { "<leader>dv", "<cmd>DiffviewToggle<cr>", desc = "Toggle Diffview" },

      -- Diff working directory
      { "<leader>do", "<cmd>DiffviewOpen<cr>", desc = "Diffview open" },
      { "<leader>dc", "<cmd>DiffviewClose<cr>", desc = "Diffview close" },

      -- File history
      { "<leader>dh", "<cmd>DiffviewFileHistory %<cr>", desc = "File history (current file)" },
      { "<leader>dH", "<cmd>DiffviewFileHistory<cr>", desc = "File history (repo)" },

      -- Visual mode: history for selection
      {
        "<leader>dh",
        "<Esc><cmd>'<,'>DiffviewFileHistory --follow<CR>",
        mode = "v",
        desc = "Range history",
      },

      -- Single line history
      { "<leader>dl", "<cmd>.DiffviewFileHistory --follow<CR>", desc = "Line history" },

      -- Diff against main/master branch (useful before merging)
      {
        "<leader>dm",
        function()
          -- Try main first, fall back to master
          local result = vim.fn.systemlist({ "git", "rev-parse", "--verify", "main" })
          local ok = vim.v.shell_error == 0 and result[1] ~= nil and result[1] ~= ""
          local branch = ok and "main" or "master"
          vim.cmd("DiffviewOpen " .. branch)
        end,
        desc = "Diff against main/master",
      },
    },
  },
}

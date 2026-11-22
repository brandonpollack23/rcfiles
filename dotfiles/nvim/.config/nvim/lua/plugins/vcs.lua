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
    config = function(_, opts)
      local jj = require("jj-signs")
      jj.setup(opts)
      -- jj-signs runs `jj root` with cwd = dirname(bufname) and doesn't skip
      -- URI buffers (zipfile://...jar::clojure/core.clj from clojure-lsp/REPL
      -- go-to-definition, fugitive://, oil://, ...), which throws ENOENT.
      local attach = jj.attach
      jj.attach = function(bufnr)
        bufnr = bufnr or vim.api.nvim_get_current_buf()
        local name = vim.api.nvim_buf_get_name(bufnr)
        if name:match("^%a[%w+.-]*://") or vim.fn.isdirectory(vim.fn.fnamemodify(name, ":h")) == 0 then
          return
        end
        return attach(bufnr)
      end
    end,
  },
  -- diff view for merge conflicts
  {
    "dlyongemallo/diffview-plus.nvim",
    version = "*",
    cmd = {
      "DiffviewClose",
      "DiffviewDiffDirs",
      "DiffviewDiffFiles",
      "DiffviewFileHistory",
      "DiffviewFocusFiles",
      "DiffviewLog",
      "DiffviewMergeFiles",
      "DiffviewOpen",
      "DiffviewRefresh",
      "DiffviewToggle",
      "DiffviewToggleFiles",
    },
    -- diffchar.vim gives character-level diff precision, pairs with enhanced_diff_hl below
    dependencies = { "rickhowe/diffchar.vim" },
    opts = {
      enhanced_diff_hl = true,
      diffopt = { algorithm = "histogram" },
      view = {
        merge_tool = {
          layout = "diff4_mixed",
          disable_diagnostics = true,
          winbar_info = true,
        },
        cycle_layouts = {
          merge_tool = { "diff4_mixed", "diff3_mixed", "diff3_horizontal", "diff1_plain" },
        },
      },
    },
    keys = {
      -- Toggle diffview open/close
      { "<leader>zv", "<cmd>DiffviewToggle<cr>", desc = "Toggle Diffview" },

      -- Diff working directory
      { "<leader>zo", "<cmd>DiffviewOpen<cr>", desc = "Diffview open" },
      { "<leader>zc", "<cmd>DiffviewClose<cr>", desc = "Diffview close" },

      -- File history
      { "<leader>zh", "<cmd>DiffviewFileHistory %<cr>", desc = "File history (current file)" },
      { "<leader>zH", "<cmd>DiffviewFileHistory<cr>", desc = "File history (repo)" },

      -- Visual mode: history for selection
      {
        "<leader>zh",
        "<Esc><cmd>'<,'>DiffviewFileHistory --follow<CR>",
        mode = "v",
        desc = "Range history",
      },

      -- Single line history
      { "<leader>zl", "<cmd>.DiffviewFileHistory --follow<CR>", desc = "Line history" },

      -- Diff against main/master branch (useful before merging)
      {
        "<leader>zm",
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
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>z", group = "Diffview (vcs)" },
      },
    },
  },
}

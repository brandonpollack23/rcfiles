return {
  {
    'lewis6991/gitsigns.nvim',
    config = function()
      local gs = require('gitsigns')
      gs.setup {
        current_line_blame = false, --buggy because of https://github.com/lewis6991/gitsigns.nvim/issues/368
        current_line_blame_opts = {
          virt_text_pos = 'right_align',
          delay = 250,
          virt_text_priority = 1000,
        },
        current_line_blame_formatter = function(name, blame_info, opts)
          if blame_info.author == name then
            blame_info.author = 'You'
          end
          local row = vim.api.nvim_win_get_cursor(0)[1]
          local len = #vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
          -- Iterate over extmarks to find virtual text and add their lengths
          local extmarks = vim.api.nvim_buf_get_extmarks(0, -1, { row, 0 }, { row, -1 }, { details = true })
          for _, extmark in ipairs(extmarks) do
            local details = extmark[4]
            if details and details.virt_text then
              for _, chunk in ipairs(details.virt_text) do
                local text = chunk[1]
                len = len + #text
              end
            end
          end

          local text
          if len > 80 then
            -- truncate text on long lines.
            text = ''
          elseif blame_info.author == 'Not Committed Yet' then
            text = blame_info.author
          else
            local date_time

            if opts ~= nil and opts.relative_time then
              date_time = require('gitsigns.util').get_relative_time(tonumber(blame_info['author_time']))
            else
              date_time = os.date('%Y-%m-%d', tonumber(blame_info['author_time']))
            end

            text = string.format('%s, %s - %s', blame_info.author, date_time, blame_info.summary)
          end

          if text ~= '' then
            text = ' ' .. text
          end

          return { { text, 'GitSignsCurrentLineBlame' } }
        end,
        on_attach = function(bufnr)
          local wk = require('which-key')

          wk.add({
            -- Normal mode git operations
            { "<leader>g", group = "Git" },
            { "<leader>gn", gs.next_hunk, desc = "Next git hunk" },
            { "<leader>gN", gs.prev_hunk, desc = "Prev git hunk" },
            { "<leader>gR", gs.reset_buffer, desc = "Reset buffer" },
            { "<leader>gh", group = "hunk operations" },
            { "<leader>ghp", gs.preview_hunk, desc = "Preview hunk" },
            { "<leader>ghs", function() gs.stage_hunk { vim.fn.line('.'), vim.fn.line('v') } end, desc = "Stage hunk" },
            { "<leader>ghd", gs.diffthis, desc = "Diff against index" },
            { "<leader>ghD", function() gs.diffthis('~') end, desc = "Diff against last commit" },
            { "<leader>ghr", function() gs.reset_hunk { vim.fn.line('.'), vim.fn.line('v') } end, desc = "Reset hunk" },
            
            -- Visual mode git operations
            { "<leader>g", group = "Git", mode = "x" },
            { "<leader>gn", gs.next_hunk, desc = "Next git hunk", mode = "x" },
            { "<leader>gN", gs.prev_hunk, desc = "Prev git hunk", mode = "x" },
            { "<leader>gR", gs.reset_buffer, desc = "Reset buffer", mode = "x" },
            { "<leader>gh", group = "hunk operations", mode = "x" },
            { "<leader>ghp", gs.preview_hunk, desc = "Preview hunk", mode = "x" },
            { "<leader>ghs", function() gs.stage_hunk { vim.fn.line('.'), vim.fn.line('v') } end, desc = "Stage hunk", mode = "x" },
            { "<leader>ghd", gs.diffthis, desc = "Diff against index", mode = "x" },
            { "<leader>ghD", function() gs.diffthis('~') end, desc = "Diff against last commit", mode = "x" },
            { "<leader>ghr", function() gs.reset_hunk { vim.fn.line('.'), vim.fn.line('v') } end, desc = "Reset hunk", mode = "x" },
          })
        end
      }
    end
  },
  {
    'f-person/git-blame.nvim',
    -- load the plugin at startup
    event = 'VeryLazy',
    -- Because of the keys part, you will be lazy loading this plugin.
    -- The plugin wil only load once one of the keys is used.
    -- If you want to load the plugin at startup, add something like event = "VeryLazy",
    -- or lazy = false. One of both options will work.
    opts = {
      -- your configuration comes here
      -- for example
      enabled = true, -- if you want to enable the plugin
      message_template = ' <summary> • <date> • <author> • <<sha>>', -- template for the blame message, check the Message template section for more options
      date_format = '%m-%d-%Y %H:%M:%S', -- template for the date, check Date format section for more options
      virtual_text_column = 1, -- virtual text start column, check Start virtual text at column section for more options
    },
    config = function(opts)
      vim.g.gitblame_schedule_event = 'CursorHold'
      vim.g.gitblame_display_virtual_text = 0 -- Disable virtual text, I use lualine
      require('gitblame').setup(opts)
    end
  },
  -- Git blame but like a bar
  {
    'FabijanZulj/blame.nvim',
    lazy = false,
    config = function()
      require('blame').setup {}
      require('which-key').add({
        { "<leader>g", group = "Git" },
        { "<leader>gb", ":BlameToggle<cr>", desc = "Toggle Blame" },
      })
    end,
  },
  {
    'sindrets/diffview.nvim',
    config = function()
      require('diffview').setup()
      require('which-key').add({
        { "<leader>g", group = "Git" },
        { "<leader>gd", ":DiffviewOpen<cr>", desc = "Open Diffview" },
        { "<leader>gD", ":DiffviewClose<cr>", desc = "Close Diffview" },
        { "<leader>gR", ":DiffviewRefresh<cr>", desc = "Refresh Diffview" },
        { "<leader>gh", ":DiffviewFileHistory<cr>", desc = "File History" },
        
        -- Visual mode diffview
        { "<leader>g", group = "Git", mode = "v" },
        { "<leader>gh", ":'<,'>DiffviewFileHistory<cr>", desc = "File History (selection)", mode = "v" },
      })
    end
  },
  {
    'wintermute-cell/gitignore.nvim',
    dependencies = { 'nvim-telescope/telescope.nvim' },
    config = function()
      require('gitignore')
    end,
  },
  -- Github/octo.nvim
  {
    'pwntester/octo.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope.nvim',
      -- OR 'ibhagwan/fzf-lua',
      'nvim-tree/nvim-web-devicons',
    },
    config = function()
      require 'octo'.setup({
        use_local_fs = false,            -- use local files on right side of reviews
        default_merge_method = 'commit', -- default merge method which should be used for both `Octo pr merge` and merging from picker, could be `commit`, `rebase` or `squash`
        default_delete_branch = true,    -- whether to delete branch when merging pull request with either `Octo pr merge` or from picker (can be overridden with `delete`/`nodelete` argument to `Octo pr merge`)
      })
    end
  }
}

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

          wk.register(
            {
              g = {
                n = { gs.next_hunk, 'Next git hunk' },
                N = { gs.prev_hunk, 'Prev git hunk' },
                R = { gs.reset_buffer, 'Reset buffer' },
                h = {
                  name = 'hunk operations',
                  p = { gs.preview_hunk, 'Preview hunk' },
                  s = { function() gs.stage_hunk { vim.fn.line('.'), vim.fn.line('v') } end, 'Stage hunk' },
                  d = { gs.diffthis, 'Diff against index' },
                  D = { function() gs.diffthis('~') end, 'Diff against last commit' },
                  r = { function() gs.reset_hunk { vim.fn.line('.'), vim.fn.line('v') } end, 'Reset hunk' },
                },
              }
            },
            { prefix = '<leader>' }
          )
          wk.register(
            {
              g = {
                n = { gs.next_hunk, 'Next git hunk' },
                N = { gs.prev_hunk, 'Prev git hunk' },
                R = { gs.reset_buffer, 'Reset buffer' },
                h = {
                  name = 'hunk operations',
                  p = { gs.preview_hunk, 'Preview hunk' },
                  s = { function() gs.stage_hunk { vim.fn.line('.'), vim.fn.line('v') } end, 'Stage hunk' },
                  d = { gs.diffthis, 'Diff against index' },
                  D = { function() gs.diffthis('~') end, 'Diff against last commit' },
                  r = { function() gs.reset_hunk { vim.fn.line('.'), vim.fn.line('v') } end, 'Reset hunk' },
                },
              }
            },
            { mode = 'x', prefix = '<leader>' }
          )
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
    config = function()
      vim.g.gitblame_schedule_event = 'CursorHold'
      vim.g.gitblame_display_virtual_text = 0 -- Disable virtual text, I use lualine
      require('git-blame').setup()
    end
  },
  {
    'sindrets/diffview.nvim',
    config = function()
      require('diffview').setup()
      require('which-key').register({
          g = {
            name = 'Git',
            d = { ':DiffviewOpen<cr>', 'Open Diffview' },
            D = { ':DiffviewClose<cr>', 'Close Diffview' },
            R = { ':DiffviewRefresh<cr>', 'Refresh Diffview' },
            h = { ':DiffviewFileHistory<cr>', 'File History' },
          }
        },
        { prefix = '<leader>' }
      )

      require('which-key').register(
        {
          g = {
            name = 'Git',
            h = { ":'<,'>DiffviewFileHistory<cr>", 'File History (selection)' },
          }
        },
        { prefix = '<leader>', mode = 'v' }
      )
    end
  },
  {
    'wintermute-cell/gitignore.nvim',
    dependencies = { 'nvim-telescope/telescope.nvim' },
    config = function()
      require('gitignore')
    end,
  },
}

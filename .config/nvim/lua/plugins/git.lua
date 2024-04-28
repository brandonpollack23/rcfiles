return {
  {
    'lewis6991/gitsigns.nvim',
    config = function()
      local gs = require('gitsigns')
      gs.setup {
        current_line_blame = true,
        current_line_blame_opts = {
          virt_text_pos = 'right_align',
          delay = 50,
        },
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

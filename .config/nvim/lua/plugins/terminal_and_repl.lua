return {
  {
    'akinsho/toggleterm.nvim',
    version = '*',
    config = function()
      if vim.fn.has('win32') == 1 then
        vim.cmd [[let &shell = '"C:/Program Files/Git/bin/bash.exe"']]
        vim.cmd [[let &shellcmdflag = '-s']]
      end

      local sessionNamePrefix = vim.fn.getcwd() .. '#nvim'
      -- TODO binding to cycle through these
      local terminal_type = 'horizontal'
      require('toggleterm').setup {
        size = function(term)
          if term.direction == 'horizontal' then
            return 20
          elseif term.direction == 'vertical' then
            return 50
          end
        end,
        open_mapping = [[<c-\>]],
        direction = terminal_type,
        on_create = function(term)
          if vim.fn.has('win32') == 1 then
            return
          end

          -- vim.notify(
          --   'Remember to prefix twice <C-a> C<C-a> to send to tmux in nvim if already running in tmux')
          -- term:send(' export HISTCONTROL=ignorespace', false)
          -- term:send(' tmux new-session -A -s ' .. sessionNamePrefix .. term.id, false)
          -- TODO wezterm session saving of terminal.
          term:send(' export NVIM=' .. vim.v.servername)
        end,
        on_open = function(term)
          vim.cmd('startinsert')
        end,
        on_close = function(term)
        end,
        float_opts = {
          -- The border key is *almost* the same as 'nvim_open_win'
          -- see :h nvim_open_win for details on borders however
          -- the 'curved' border is a custom border type
          -- not natively supported but implemented in this plugin.
          -- border = 'single' | 'double' | 'shadow' | 'curved' | ... other options supported by win open
          border = 'double',
          -- like `size`, width, height, row, and col can be a number or function which is passed the current terminal
          winblend = 20,
          title_pos = 'left',
        },
      }

      local wk = require('which-key')
      wk.register({
        ['<C-\\>'] = { ':ToggleTerm<cr>', 'Toggle Terminal, takes a prefix for term #' },
      }, {})
      wk.register(
        {
          t = {
            name = 'Terminals',
            t = { ':ToggleTerm<cr>', 'Toggle Terminal' },
            s = { ':TermSelect<cr>', 'Select from list of open terminals' },
            n = {
              function()
                local term = require('toggleterm.terminal')
                    .get_last_focused()
                -- check a terminal exists
                if not term then
                  vim.notify('No terminal to rename')
                  return
                end

                local name = vim.fn.input('Set name of a terminal: ')
                vim.cmd('ToggleTermSetName ' .. name)
              end,
              'Set terminal name'
            },
            e = { ':ToggleTermSendCurrentLine<cr>', 'Execute current line in terminal' },
          }
        },
        { prefix = '<leader>' }
      )

      wk.register(
        {
          t = {
            name = 'Terminals',
            e = { ':ToggleTermSendVisualSelection<cr>', 'Execute current selection in terminal' },
          },
        },
        {
          prefix = '<leader>',
          mode = 'v',
        }
      )

      -- Return to normal mode from terminal mode to leave terminal open etc
      vim.keymap.set('t', '<C-/>', function() vim.cmd('stopinsert') end, { noremap = true })
    end
  },
  {
    'willothy/flatten.nvim',
    dependencies = { 'akinsho/toggleterm.nvim' },
    lazy = false,
    priority = 1001,
    config = function()
      ---@type Terminal?
      local saved_terminal

      require('flatten').setup {
        window = {
          open = 'alternate',
        },
        hooks = {
          should_block = function(argv)
            -- Note that argv contains all the parts of the CLI command, including
            -- Neovim's path, commands, options and files.
            -- See: :help v:argv

            -- In this case, we would block if we find the `-b` flag
            -- This allows you to use `nvim -b file1` instead of
            -- `nvim --cmd 'let g:flatten_wait=1' file1`
            return vim.tbl_contains(argv, '-b')

            -- Alternatively, we can block if we find the diff-mode option
            -- return vim.tbl_contains(argv, "-d")
          end,
          pre_open = function()
            local term = require('toggleterm.terminal')
            local termid = term.get_focused_id()
            saved_terminal = term.get(termid)
          end,
          post_open = function(bufnr, winnr, ft, is_blocking)
            if is_blocking and saved_terminal then
              -- Hide the terminal while it's blocking
              saved_terminal:close()
            else
              -- If it's a normal file, just switch to its window
              vim.api.nvim_set_current_win(winnr)
            end

            -- If the file is a git commit, create one-shot autocmd to delete its buffer on write
            -- If you just want the toggleable terminal integration, ignore this bit
            if ft == 'gitcommit' or ft == 'gitrebase' then
              vim.api.nvim_create_autocmd('BufWritePost', {
                buffer = bufnr,
                once = true,
                callback = vim.schedule_wrap(function()
                  vim.api.nvim_buf_delete(bufnr, {})
                end),
              })
            end
          end,
          block_end = function()
            -- After blocking ends (for a git commit, etc), reopen the terminal
            vim.schedule(function()
              if saved_terminal then
                saved_terminal:open()
                saved_terminal = nil
              end
            end)
          end,
        },
      }
    end,
  },

  {
    'Vigemus/iron.nvim',
    config = function()
      local iron = require('iron.core')

      iron.setup {
        config = {
          -- Whether a repl should be discarded or not
          scratch_repl = true,
          -- Your repl definitions come here
          repl_definition = {
            python = {
              command = { 'uv' }
            },
            sh = {
              -- Can be a table or a function that
              -- returns a table (see below)
              command = { 'zsh' }
            },
            haskell = {
              command = { 'stack', 'ghci' }
            },
            elixir = {
              command = { 'iex', '-S', 'mix' }
            },
            rust = {
              command = { 'evxcr' }
            },
            typescript = {
              command = { 'ts-node' }
            },
          },
          -- How the repl window will be displayed
          -- See below for more information
          repl_open_cmd = require('iron.view').split.vertical.botright(.40),
        },
        -- Iron doesn't set keymaps by default anymore.
        -- You can set them here or manually add keymaps to the functions in iron.core
        keymaps = {
          toggle_repl = '<space>rr', -- toggles the repl open and closed.
          -- If repl_open_command is a table as above, then the following keymaps are
          -- available
          -- toggle_repl_with_cmd_1 = "<space>rv",
          -- toggle_repl_with_cmd_2 = "<space>rh",
          restart_repl = '<space>rR', -- calls `IronRestart` to restart the repl
          send_motion = '<space>sc',
          visual_send = '<space>sc',
          send_file = '<space>sf',
          send_line = '<space>sl',
          send_paragraph = '<space>sp',
          send_until_cursor = '<space>su',
          send_mark = '<space>sm',
          send_code_block = '<space>sb',
          send_code_block_and_move = '<space>sn',
          mark_motion = '<space>mc',
          mark_visual = '<space>mc',
          remove_mark = '<space>md',
          cr = '<space>s<cr>',
          interrupt = '<space>s<space>',
          exit = '<space>sq',
          clear = '<space>cl',
        },
        -- If the highlight is on, you can change how it looks
        -- For the available options, check nvim_set_hl
        highlight = {
          italic = true
        },
        ignore_blank_lines = true, -- ignore blank lines when sending visual select lines
      }

      local wk = require('which-key')
      wk.add({
        { '<space>',  group = 'Repl/Jupyter' },
        { '<space>r', group = 'Repl' },
        { '<space>s', group = 'Send to Repl' },
      })
    end
  }
}

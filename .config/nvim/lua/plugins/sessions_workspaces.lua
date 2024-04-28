return {
  -- Terminal that toggles like vscode
  -- Sessions and workspaces
  {
    'natecraddock/sessions.nvim',
    lazy = false,
    config = function()
      local sessions = require('sessions')

      local dir = vim.fn.stdpath('data') .. '/sessions'
      vim.fn.mkdir(dir, 'p')

      sessions.setup {
        session_filepath = dir,
        absolute = true,
      }

      sessions.start_autosave()
    end
  },
  {
    'natecraddock/workspaces.nvim',
    dependencies = {
      'natecraddock/sessions.nvim',
      'nvim-telescope/telescope.nvim',
    },

    build = function()
      local workspaces = require('workspaces')

      local project_directories = (os.getenv('PROJECT_DIRS') or '')
      for dir in string.gmatch(project_directories, '[^:]+') do
        workspaces.add_dir(dir)
      end

      workspaces.add(vim.fn.expand('$HOME/rcfiles/.config/nvim'), 'Neovim Configuration')
      workspaces.add(vim.fn.expand('$HOME/rcfiles/'), 'rcfiles')
    end,

    config = function()
      local workspaces = require('workspaces')
      workspaces.sync_dirs()

      require('which-key').register({
          w = {
            name = 'Workspaces and sessons',
            w = { ':Telescope workspaces<cr>', 'Open Workspaces (fuzzy)' },
            a = { ':WorkspacesAdd<cr>', 'Add current directory to workspaces' },
            l = { ':SessionsLoad<cr>', 'Load default session for workspace' },
          }
        },
        { prefix = '<leader>' }
      )

      workspaces.setup({
        hooks = {
          open_pre = {
            -- Stop current session and delete all buffers
            'SessionsStop',
            'silent %bdelete!'
          },
          open = function()
            local loaded = require('sessions').load(nil, { silent = true })
            if not loaded then
              require('sessions').start_autosave()
            end
          end,
        }
      })
    end
  },
}

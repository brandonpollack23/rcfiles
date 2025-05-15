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
      workspaces.add(vim.fn.expand('$HOME/.local/share/nvim/lazy'), 'nvim lazy packages')
    end,

    config = function()
      local workspaces = require('workspaces')
      -- Suppress sync message by redirecting output
      vim.cmd('silent! lua require("workspaces").sync_dirs()')

      require('which-key').add({
        { "<leader>w", group = "Workspaces and sessons" },
        { "<leader>ww", ":Telescope workspaces<cr>", desc = "Open Workspaces (fuzzy)" },
        { "<leader>wa", ":WorkspacesAdd<cr>", desc = "Add current directory to workspaces" },
        { "<leader>wl", ":SessionsLoad<cr>", desc = "Load default session for workspace" },
      })

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

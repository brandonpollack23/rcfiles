return {
  -- {
  --   'benlubas/molten-nvim',
  --   version = '^1.0.0', -- use version <2.0.0 to avoid breaking changes
  --   dependencies = { '3rd/image.nvim' },
  --   build = ':UpdateRemotePlugins',
  --   init = function()
  --     -- these are examples, not defaults. Please see the readme
  --     vim.g.molten_image_provider = 'image.nvim'
  --     vim.g.molten_output_win_max_height = 20
  --
  --     local wk = require('which-key')
  --     wk.add({
  --       { '<space>',  group = 'REPL/Jupyter' },
  --       { '<space>i', ':MoltenInit<CR>', desc = 'Initialize jupyter for buffer' },
  --       { '<space>D', ':MoltenDeinit<CR>', desc = 'Deinit jupyter for buffer' },
  --       { '<space>I', ':MoltenInfo<CR>', desc = 'Show info jupyter state' },
  --       { '<space>n', ':MoltenNext<CR>', desc = 'Next cell' },
  --       { '<space>p', ':MoltenPrev<CR>', desc = 'Prev cell' },
  --       { '<space>e', ':<C-u>MoltenEvaluateOperator<CR>', desc = 'Molten Evaluate' },
  --       { '<space>v', ':MoltenEvaluateVisual<CR>', desc = 'Molten Evaluate Selection', mode = 'v',  },
  --       { '<space>x', ':MoltenReevaluateCell<CR>', desc = '(Re)Evaluate Cell' },
  --       { '<space>h', ':MoltenHideOutput<CR>', desc = 'Hide output window' },
  --       { '<space>H', ':MoltenShow<CR>', desc = 'Show output window' },
  --       { '<space>!', ':MoltenInterrupt<CR>', desc = 'Interrupt hanging execution' },
  --     })
  --   end,
  -- },

  {
    'kiyoon/jupynium.nvim',
    dependencies = {
      'rcarriga/nvim-notify',
    },
    build = function()
      os.execute('uv pip install notebook --python=$HOME/.config/nvim/.venv/bin/python')
      os.execute('uv pip install nbclassic --python=$HOME/.config/nvim/.venv/bin/python')
      os.execute('uv pip install jupyter-console --python=$HOME/.config/nvim/.venv/bin/python')
      os.execute('uv pip install . --python=$HOME/.config/nvim/.venv/bin/python')

      -- Rust kernel installation
      os.execute('cargo install --locked evcxr_jupyter')
      os.execute('evcxr_jupyter --install')
    end,
    config = function()
      require('jupynium').setup({
        --- For Conda environment named "jupynium",
        -- python_host = { "conda", "run", "--no-capture-output", "-n", "jupynium", "python" },
        python_host = vim.g.python3_host_prog,

        default_notebook_URL = 'localhost:8888/nbclassic',

        -- Write jupyter command but without "notebook"
        -- When you call :JupyniumStartAndAttachToServer and no notebook is open,
        -- then Jupynium will open the server for you using this command. (only when notebook_URL is localhost)
        -- jupyter_command = os.getenv('HOME') .. '/.config/nvim/.venv/bin/jupyter',
        jupyter_command = {'uv', 'run', 'jupyter'},
        --- For Conda, maybe use base environment
        --- then you can `conda install -n base nb_conda_kernels` to switch environment in Jupyter Notebook
        -- jupyter_command = { "conda", "run", "--no-capture-output", "-n", "base", "jupyter" },

        -- Used when notebook is launched by using jupyter_command.
        -- If nil or "", it will open at the git directory of the current buffer,
        -- but still navigate to the directory of the current buffer. (e.g. localhost:8888/nbclassic/tree/path/to/buffer)
        notebook_dir = nil,

        -- Used to remember the last session (password etc.).
        -- e.g. '~/.mozilla/firefox/profiles.ini'
        -- or '~/snap/firefox/common/.mozilla/firefox/profiles.ini'
        firefox_profiles_ini_path = nil,
        -- nil means the profile with Default=1
        -- or set to something like 'default-release'
        firefox_profile_name = nil,

        -- Open the Jupynium server if it is not already running
        -- which means that it will open the Selenium browser when you open this file.
        -- Related command :JupyniumStartAndAttachToServer
        auto_start_server = {
          enable = false,
          file_pattern = { '*.ju.*' },
        },

        -- Attach current nvim to the Jupynium server
        -- Without this step, you can't use :JupyniumStartSync
        -- Related command :JupyniumAttachToServer
        auto_attach_to_server = {
          enable = true,
          file_pattern = { '*.ju.*', '*.md' },
        },

        -- Automatically open an Untitled.ipynb file on Notebook
        -- when you open a .ju.py file on nvim.
        -- Related command :JupyniumStartSync
        auto_start_sync = {
          enable = false,
          file_pattern = { '*.ju.*', '*.md' },
        },

        -- Automatically keep filename.ipynb copy of filename.ju.py
        -- by downloading from the Jupyter Notebook server.
        -- WARNING: this will overwrite the file without asking
        -- Related command :JupyniumDownloadIpynb
        auto_download_ipynb = true,

        -- Automatically close tab that is in sync when you close buffer in vim.
        auto_close_tab = true,

        -- Always scroll to the current cell.
        -- Related command :JupyniumScrollToCell
        autoscroll = {
          enable = true,
          mode = 'always', -- "always" or "invisible"
          cell = {
            top_margin_percent = 20,
          },
        },

        scroll = {
          page = { step = 0.5 },
          cell = {
            top_margin_percent = 20,
          },
        },

        -- Files to be detected as a jupynium file.
        -- Add highlighting, keybindings, commands (e.g. :JupyniumStartAndAttachToServer)
        -- Modify this if you already have lots of files in Jupytext format, for example.
        jupynium_file_pattern = { '*.ju.*' },

        use_default_keybindings = true,
        textobjects = {
          use_default_keybindings = true,
        },

        syntax_highlight = {
          enable = true,
        },

        -- Dim all cells except the current one
        -- Related command :JupyniumShortsightedToggle
        shortsighted = false,

        -- Configure floating window options
        -- Related command :JupyniumKernelHover
        kernel_hover = {
          floating_win_opts = {
            max_width = 84,
            border = 'none',
          },
        },

        notify = {
          ignore = {
            -- "download_ipynb",
            -- "error_download_ipynb",
            -- "attach_and_init",
            -- "error_close_main_page",
            -- "notebook_closed",
          },
        },
      })

      -- You can link highlighting groups.
      -- This is the default (when colour scheme is unknown)
      -- Try with CursorColumn, Pmenu, Folded etc.
      vim.cmd [[
hi! link JupyniumCodeCellSeparator CursorLine
hi! link JupyniumMarkdownCellSeparator CursorLine
hi! link JupyniumMarkdownCellContent CursorLine
hi! link JupyniumMagicCommand Keyword
]]

      local wk = require('which-key')
      wk.add({
        { '<leader>j',  group = 'Jupyter Notebook' },
        { '<leader>js', ':JupyniumStartAndAttachToServer<CR>', desc = 'Start jupynium server' },
        { '<leader>jj', ':JupyniumStartSync<CR>',              desc = 'Start jupynium sync to file' },
        { '<leader>jJ', ':JupyniumStopSync<CR>',               desc = 'Stop sync' },
        { '<leader>ja', ':JupyniumAttachToServer<CR>',         desc = 'Attach to an already running server (for downloading .ju.* from ipynb)' },
        { '<leader>jR', ':JupyniumKernelRestart<CR>',          desc = 'Restart kernel' },
        { '<leader>jc', ':JupyniumKernelInterrupt<CR>',        desc = 'Interrupt kernel' },
        { '<leader>jp', ':JupyniumScrollUp<CR>',               desc = 'Scroll up jupynium browser' },
        { '<leader>jn', ':JupyniumScrollDown<CR>',             desc = 'Scroll down jupynium browser' },
      })

      -- Please share your favourite settings on other colour schemes, so I can add defaults.
      -- Currently, tokyonight is supported.
    end
  },
}

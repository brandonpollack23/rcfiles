-- Function that detects if there is a "cmd" directory in the project root and walks the files in there to see if there is a main function in a main package in any go files there and returns the list of them
local function get_go_main_files()
  vim.notify(
    'Searching for main files in cmd directory, if there are more you will need to add them manually to a launch.json or a local nvim configuration',
    vim.log.levels.TRACE)

  local cmd_dir = './cmd'
  local main_files = {}
  if vim.fn.isdirectory(cmd_dir) == 0 then
    return main_files
  end

  local files = vim.fn.readdir(cmd_dir)
  for _, file in ipairs(files) do
    local full_path = cmd_dir .. '/' .. file
    vim.notify('Checking file: ' .. full_path, vim.log.levels.TRACE)
    if vim.fn.isdirectory(full_path) == 0 then
      local file_contents = vim.fn.readfile(full_path)
      for _, line in ipairs(file_contents) do
        if string.match(line, '^%s*func main') then
          table.insert(main_files, full_path)
          break
        end
      end
    end
  end

  return main_files
end

return {
  { 'williamboman/mason.nvim' },
  { 'williamboman/mason-lspconfig.nvim' },
  {
    'mfussenegger/nvim-dap',
    dependencies = { 'Weissle/persistent-breakpoints.nvim', lazy = false },
    config = function()
      local dap = require('dap')
      dap.set_log_level('INFO') -- Helps when configuring DAP, see logs with :DapShowLog

      vim.fn.sign_define('DapBreakpoint', { text = '🛑', texthl = '', linehl = '', numhl = '' })
      vim.fn.sign_define('DapLogPoint', { text = '🪵', texthl = '', linehl = '', numhl = '' })
      vim.fn.sign_define('DapStopped', { text = '➡️', texthl = '', linehl = '', numhl = '' })
      vim.fn.sign_define('DapBreakpointCondition', { text = '🚥', texthl = '', linehl = '', numhl = '' })
      vim.fn.sign_define('DapBreakpointRejected', { text = '⭕', texthl = '', linehl = '', numhl = '' })

      -- Debug Configurations
      -- I default to using the vscode json format because it's more common and can be configured per project without another dependency.
      -- For handling inputs, or multiple platforms in launch.json, see dap.txt or the docs on vscode launch.json
      require('dap.ext.vscode').load_launchjs(nil,
        {
          delve = { 'go', },
        }
      )

      -- Add configurations for certain languages

      -- Go
      if vim.loop.fs_stat(vim.fn.getcwd() .. '/go.mod') ~= nil then
        for _, file in ipairs(get_go_main_files()) do
          -- extend dap.configurations
          if dap.configurations.go == nil then
            dap.configurations.go = {}
          end
          table.insert(dap.configurations.go,
            {
              type = 'delve',
              name = 'Autodetected Binary - ' .. file,
              request = 'launch',
              program = file,
            }
          )
        end
      end

      -- TODO for tests see how rayx does it with :GoDebug -t and :GoDebug -n
      -- https://github.com/ray-x/go.nvim?tab=readme-ov-file#debug


      -- Here is how to do it in Lua if i need, but this is handled usually by mason-dap
      -- dap.configurations = {
      --   go = {
      --     {
      --       type = 'delve',         -- Which adapter to use
      --       name = 'Debug',      -- Human readable name
      --       request = 'launch',  -- Whether to "launch" or "attach" to program
      --       program = '${file}', -- The buffer you are focused on when running nvim-dap
      --     },
      --   }
      -- }

      -- Debug adapters
      -- dap.adapters = {
      --   delve = {
      --     type = 'server',
      --     port = '${port}',
      --     executable = {
      --       command = vim.fn.stdpath('data') .. '/mason/bin/dlv',
      --       args = { 'dap', '-l', '127.0.0.1:${port}' },
      --     },
      --   }
      -- }

      require('persistent-breakpoints').setup({
        load_breakpoints_event = { 'BufReadPost' }
      })
      local persistentBreakpoints = require('persistent-breakpoints.api')
      local wk = require('which-key')
      wk.register({
          -- e because d is already used for tree operations and e is the same finger as d
          e = {
            name = 'Debugging',
            b = { persistentBreakpoints.toggle_breakpoint, 'Toggle breakpoint' },
            B = { persistentBreakpoints.set_conditional_breakpoint, 'Set Conditional breakpoint' },
            z = { persistentBreakpoints.clear_all_breakpoints, 'Clear breakpoints' },
            E = { dap.set_exception_breakpoints, 'Set exception breakpoints' },
            c = { dap.continue, 'Start/Continue' },
            C = { dap.run_last, 'Start/Continue Last configuration' },
            r = { dap.restart, 'Restart' },
            g = { dap.run_to_cursor, 'Run to cursor' },
            i = { dap.step_into, 'Step into' },
            j = { dap.step_over, 'Step over' },
            k = { dap.step_back, 'Step back (if supported)' },
            O = { dap.step_out, 'Step out' },
            S = { dap.terminate, 'Stop' },
          }
        },
        {
          prefix = '<leader>',
        })
      wk.register({
        ['<F5>'] = { dap.continue, 'Start/Continue Debugger' },
        ['<F10>'] = { dap.step_over, 'Step Over Debugger' },
        ['<F11>'] = { dap.step_into, 'Step In Debugger' },
        ['<F12>'] = { dap.step_out, 'Step In Debugger' },
      })
    end
  },
  {
    'Weissle/persistent-breakpoints.nvim',
    config = function()
      require('persistent-breakpoints').setup {
        load_breakpoints_event = { 'BufReadPost' }
      }
    end
  },
  {
    'rcarriga/nvim-dap-ui',
    dependencies = { 'mfussenegger/nvim-dap', 'nvim-neotest/nvim-nio' },
    config = function()
      local dapui = require('dapui')
      local dap = require('dap')

      dapui.setup({
        mappings = {
          open = 'o',
          remove = 'd',
          edit = 'e',
          repl = 'r',
          toggle = 't',
        },
        expand_lines = vim.fn.has('nvim-0.7'),
      })

      -- Auto open and close the DAP UI when debugging
      dap.listeners.before.attach.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.launch.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated.dapui_config = function()
        dapui.close()
      end
      dap.listeners.before.event_exited.dapui_config = function()
        dapui.close()
      end
    end
  },
  { 'jay-babu/mason-nvim-dap.nvim' },
  { 'VonHeikemen/lsp-zero.nvim',   branch = 'v3.x' },
  { 'neovim/nvim-lspconfig' },
  { 'hrsh7th/nvim-cmp' },
  { 'hrsh7th/cmp-nvim-lsp' },
  { 'hrsh7th/cmp-buffer' },
  { 'hrsh7th/cmp-path' },
  {
    'ray-x/lsp_signature.nvim',
    event = 'VeryLazy',
    opts = {
      hint_enable = false,
      handler_opts = {
        border = 'rounded',
      }
    },
    config = function(_, opts) require 'lsp_signature'.setup(opts) end
  },
  {
    'L3MON4D3/LuaSnip',
    dependencies = { 'rafamadriz/friendly-snippets', 'saadparwaiz1/cmp_luasnip', 'benfowler/telescope-luasnip.nvim' },
    config = function()
      require('luasnip.loaders.from_vscode').lazy_load()
      -- require('brpol.snippets.first_snippet')
      require('telescope').load_extension('luasnip')

      -- Tab is set up to balance between all its uses in remap.lua
    end
  },
  -- Causing bugs in unity
  -- {
  --   'mhanberg/output-panel.nvim',
  --   event = 'VeryLazy',
  --   config = function()
  --     require('output_panel').setup()
  --   end
  -- },

  -- Refactor stuff when LSP doesnt work
  {
    'ThePrimeagen/refactoring.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
      'nvim-telescope/telescope.nvim',
    },
    config = function()
      require('refactoring').setup()
      require('telescope').load_extension('refactoring')

      local wk = require('which-key')
      wk.register({
          r = {
            name = 'Refactors',
            e = { ':Refactor extract<CR>', 'Extract function' },
            f = { ':Refactor extract_to_file<CR>', 'Extract function to file' },
            v = { ':Refactor extract_var<CR>', 'Extract variable' },
          }
        },
        {
          mode = 'x',
          prefix = '<leader>',
        })

      local sharedBindings = {
        r = {
          name = 'Refactors',
          r = { function() require('refactoring').select_refactor() end, 'Select refactor' },
          i = { ':Refactor inline_var<CR>', 'Inline variable' },
          B = { ':Refactor extract_block_to_file<CR>', 'Extract block to file' },
        }
      }
      wk.register(sharedBindings,
        {
          mode = 'x',
          prefix = '<leader>',
        })
      wk.register(sharedBindings,
        {
          mode = 'n',
          prefix = '<leader>',
        })

      wk.register({
          r = {
            name = 'Refactors',
            I = { ':Refactor inline_func<CR>', 'Inline function' },
            b = { ':Refactor extract_block<CR>', 'Extract block' },
          }
        },
        {
          mode = 'n',
          prefix = '<leader>',
        })
    end,
  },

  {
    'antosha417/nvim-lsp-file-operations',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-tree.lua',
    },
    config = function()
      require('lsp-file-operations').setup()
    end,
  },

  -- Github copilot
  {
    'zbirenbaum/copilot.lua',
    build = function()
      vim.cmd('Copilot auth')
    end,
    config = function()
      local copilot = require('copilot')
      copilot.setup({
        panel = {
          auto_refresh = true,
          keymap = {
            open = '<C-l>',
          }
        },
        suggestion = {
          auto_trigger = true,
          keymap = {
            -- Accept is bound in remap.lua so <Tab> can be used for completion of snippets etc as well.
            accept = nil,
            accept_word = '<M-Right>',
            next = '<M-]>',
            prev = '<M-[>',
            dismiss = '<C-]>',
          },
          filetypes = {
            ['*'] = true,
          }
        }
      })

      local copilotEnabled = true
      local function copilot_toggle()
        copilotEnabled = not copilotEnabled
        if copilotEnabled then
          vim.cmd('Copilot enable')
        else
          vim.cmd('Copilot disable')
        end
      end
      require('which-key').register({
          c = {
            name = 'Github Copilot Operations',
            T = { copilot_toggle, 'Toggle Copilot' },
          },
        },
        { prefix = '<leader>' }
      )

      -- Copilot colors
      vim.cmd('hi CopilotSuggestion guifg=Gray')
      vim.cmd('hi CopilotAnnotation guifg=Gray')
    end
  },
  {
    'CopilotC-Nvim/CopilotChat.nvim',
    dependencies = {
      { 'zbirenbaum/copilot.lua' }, -- or github/copilot.vim
      { 'nvim-lua/plenary.nvim' },  -- for curl, log wrapper
    },
    opts = {
      window = {
        layout = 'float'
      }
    },
    -- TODO copy paste this and put it in it's own file: https://github.com/jellydn/lazy-nvim-ide/blob/main/lua/plugins/extras/copilot-chat-v2.lua
    config = function()
      local chat = require('CopilotChat')
      local select = require('CopilotChat.select')

      chat.setup()

      vim.api.nvim_create_user_command('CopilotChatInline', function(args)
        chat.ask(args.args, {
          selection = select.visual,
          window = {
            layout = 'float',
            relative = 'cursor',
            width = 1,
            height = 0.2,
            row = 1,
          },
        })
      end, { nargs = '*', range = true })

      local wk = require('which-key')
      wk.register({
          c = {
            name = 'Github Copilot Operations',
            c = { ':CopilotChatInline<cr>', 'CopilotChat - Chat with current buffer' },
            e = { ':CopilotChatExplain<cr>', 'CopilotChat - Explain code' },
            gt = { ':CopilotChatTests<cr>', 'CopilotChat - Generate tests' },
            f = { ':CopilotChatFixDiagnostic<cr>', 'CopilotChat - Fix diagnostic', },
            R = { ':CopilotChatReset<cr>', 'CopilotChat - Reset chat history and clear buffer', }
          }
        },
        {
          mode = 'n',
          prefix = '<leader>',
          silent = true,
          noremap = true,
          nowait = false,
        })
    end
  },
  -- {
  --   'supermaven-inc/supermaven-nvim',
  --   config = function()
  --     require('supermaven-nvim').setup({
  --       keymaps = {
  --         accept_suggestion = '<Tab>',
  --         clear_suggestion = '<C-]>',
  --         accept_word = '<C-j>',
  --       },
  --       ignore_filetypes = { cpp = true },
  --       color = {
  --         suggestion_color = '#808080',
  --         cterm = 244,
  --       },
  --       disable_inline_completion = false, -- disables inline completion for use with cmp
  --       disable_keymaps = false            -- disables built in keymaps for more manual control
  --     })
  --   end,
  -- },
}

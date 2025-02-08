return {
  {
    'b1nhack/nvim-json5',
    build = vim.fn.has('win32') == 1 and 'powershell ./install.ps1' or './install.sh',
    lazy = false
  },
  {
    'mfussenegger/nvim-dap',
    dependencies = {
      'b1nhack/nvim-json5',
      'neovim/nvim-lspconfig',
    },
    config = function()
      local dap = require('dap')
      local dap_vscode = require('dap.ext.vscode')
      local json5 = require('json5')
      local wk = require('which-key')

      dap_vscode.json_decode = json5.parse

      wk.add({
        { '<leader>s',     group = 'Debug (DAP)' },
        { '<leader>sc',    function() dap.continue() end,   desc = 'Start/Continue' },
        { '<F5>',          function() dap.continue() end,   desc = 'Start/Continue' },
        { '<leader>sS',    function() dap.close() end,      desc = 'Stop' },
        -- set by persistent breakpoints
        -- { '<leader>sb',    function() dap.toggle_breakpoint() end, desc = 'Toggle Breakpoint' },
        { '<leader>sD',    function() dap.disconnect() end, desc = 'Disconnect' },
        { '<leader>si',    function() dap.step_into() end,  desc = 'Step Into' },
        { '<F11>',         function() dap.step_into() end,  desc = 'Step Into' },
        { '<leader>so',    function() dap.step_over() end,  desc = 'Step Over' },
        { '<F10>',         function() dap.step_over() end,  desc = 'Step Over' },
        { '<leader>sO',    function() dap.step_out() end,   desc = 'Step Out' },
        { '<Shift>-<F11>', function() dap.step_out() end,   desc = 'Step Out' },
        { '<leader>sr',    function() dap.repl.open() end,  desc = 'Open REPL' },
      })

      vim.fn.sign_define('DapBreakpoint', { text = '🛑', texthl = '', linehl = '', numhl = '' })
      vim.fn.sign_define('DapBreakpointCondition', { text = '⚡', texthl = 'Warning', linehl = '', numhl = '' })

      -- Debug Language configurations
      -- Elixir
      local elixir_ls_mason_path = vim.fn.stdpath('data') .. '/mason/bin/elixir-ls-debugger'
      dap.adapters.mix_task = {
        type = 'executable',
        command = elixir_ls_mason_path,
        args = {}
      }
      dap.configurations.elixir = {
        {
          type = 'elixir', -- Must match the adapter name set in dap.adapters
          name = 'Global Setting: Debug Mix Test (Current File)',
          request = 'launch',
          task = 'test',
          -- `taskArgs` can be used to specify a certain file or test:
          taskArgs = { '${file}' },
          projectDir = '${workspaceFolder}',
          requireFiles = {
            'test/**/test_helper.exs',
            'test/**/*_test.exs'
          }
        },
        {
          type = 'elixir',
          name = 'Global Setting: Debug Phoenix',
          request = 'launch',
          task = 'phx.server',
          projectDir = '${workspaceFolder}',
          requireFiles = {
            'lib/**/*',
            'test/**/test_helper.exs'
          }
        },
      }
    end
  },
  {
    'rcarriga/nvim-dap-ui',
    dependencies = { 'mfussenegger/nvim-dap', 'nvim-neotest/nvim-nio' },
    config = function()
      local dap = require('dap')
      local dapui = require('dapui')

      dapui.setup()
      dap.listeners.before.attach.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.launch.dapui_config = function()
        dapui.open()
      end
    end
  },
  {
    'jay-babu/mason-nvim-dap.nvim',
    dependencies = { 'williamboman/mason.nvim', 'mfussenegger/nvim-dap', },
  },
  {
    'theHamsta/nvim-dap-virtual-text',
    dependencies = { 'mfussenegger/nvim-dap', 'nvim-treesitter/nvim-treesitter' },
  },
  {
    'Weissle/persistent-breakpoints.nvim',
    dependencies = { 'rcarriga/nvim-dap-ui', 'mfussenegger/nvim-dap' },
    config = function()
      require('persistent-breakpoints').setup {
        load_breakpoints_event = { 'BufReadPost' }
      }
      local wk = require('which-key')
      wk.add({
        { '<leader>sb', function() require('persistent-breakpoints.api').toggle_breakpoint() end,          desc = 'Toggle Breakpoint' },
        { '<leader>sB', function() require('persistent-breakpoints.api').set_conditional_breakpoint() end, desc = 'Set Conditional Breakpoint' },
        { '<leader>sX', function() require('persistent-breakpoints.api').clear_all_breakpoints() end,      desc = 'Clear All Breakpoints' },
      })
    end
  }
}

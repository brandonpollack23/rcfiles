return {
  { 'williamboman/mason.nvim' },
  { 'williamboman/mason-lspconfig.nvim' },
  { 'VonHeikemen/lsp-zero.nvim',        branch = 'v3.x' },
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
      require('telescope').load_extension('luasnip')
    end
  },
  {
    'mhanberg/output-panel.nvim',
    event = 'VeryLazy',
    config = function()
      require('output_panel').setup()
    end
  },

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
    'github/copilot.vim',
    build = function()
      vim.cmd('Copilot setup')
    end,
    config = function()
      CopilotEnabled = true
      local function toggle_copilot()
        CopilotEnabled = not CopilotEnabled
        if CopilotEnabled then
          vim.cmd('Copilot enable')
          vim.notify('Copilot enabled')
        else
          vim.cmd('Copilot disable')
          vim.notify('Copilot disabled')
        end
      end

      require('which-key').register({
          c = {
            name = 'Github Copilot Operations',
            T = { toggle_copilot, 'Toggle Copilot' },
            l = { ':vert rightb Copilot panel<cr>', 'List Suggestions' },
            s = { ':<Plug>(copilot-suggest)<cr>', 'Suggest' },
            d = { ':<Plug>(copilot-dismiss)<cr>', 'Dismiss' },
            n = { ':<Plug>(copilot-next)<cr>', 'Next Suggestion' },
            p = { ':<Plug>(copilot-previous)<cr>', 'Previous Suggestion' },
          },
        },
        { prefix = '<leader>' }
      )

      -- Add keybinding for insert mode for suggestion panel
      require('which-key').register(
        {
          ['<C-l>'] = { function() vim.cmd('vert rightb Copilot panel') end, 'List suggestions' },
          ['<C-]>'] = { ':<Plug>(copilot-next)<cr>', 'Next Suggestion' },
          ['<C-[>'] = { ':<Plug>(copilot-previous)<cr>', 'Previous Suggestion' },
        },
        { mode = 'i' }
      )
    end
  },
  {
    'CopilotC-Nvim/CopilotChat.nvim',
    dependencies = {
      { 'github/copilot.vim' },    -- or github/copilot.vim
      { 'nvim-lua/plenary.nvim' }, -- for curl, log wrapper
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

}

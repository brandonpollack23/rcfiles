return {
  -- modern NERDTree
  {
    'nvim-tree/nvim-tree.lua',
    version = '*',
    lazy = false,
    dependencies = {
      'nvim-tree/nvim-web-devicons',
      {
        'JMarkin/nvim-tree.lua-float-preview',
        lazy = false,
        -- default
        opts = {
          -- Whether the float preview is enabled by default. When set to false, it has to be "toggled" on.
          toggled_on = true,
          -- wrap nvimtree commands
          wrap_nvimtree_commands = true,
          -- lines for scroll
          scroll_lines = 20,
          -- window config
          window = {
            style = 'minimal',
            relative = 'win',
            border = 'rounded',
            wrap = false,
          },
          mapping = {
            -- scroll down float buffer
            down = { '<C-d>' },
            -- scroll up float buffer
            up = { '<C-e>', '<C-u>' },
            -- enable/disable float windows
            toggle = { '<C-x>' },
          },
          -- hooks if return false preview doesn't shown
          hooks = {
            pre_open = function(path)
              -- if file > 5 MB or not text -> not preview
              local size = require('float-preview.utils').get_size(path)
              if type(size) ~= 'number' then
                return false
              end
              local is_text = require('float-preview.utils').is_text(path)
              return size < 5 and is_text
            end,
            post_open = function(bufnr)
              return true
            end,
          },
        },
      }
    },
    config = function()
      local function change_root_to_global_cwd()
        local api = require('nvim-tree.api')
        local global_cwd = vim.fn.getcwd(-1, -1)
        api.tree.change_root(global_cwd)
      end

      local nvimTree = require('nvim-tree')
      local api = require('nvim-tree.api')

      nvimTree.setup({
        on_attach = function(bufnr)
          local floatPreview = require('float-preview')
          floatPreview.attach_nvimtree(bufnr)

          local function opts(desc)
            return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
          end

          local nvimTreeApi = require('nvim-tree.api')

          -- Run Default first
          nvimTreeApi.config.mappings.default_on_attach(bufnr)
          vim.keymap.set('n', '<C-c>', change_root_to_global_cwd,
            opts('Change Root To Global CWD'))
          vim.keymap.set('n', '?', nvimTreeApi.tree.toggle_help, opts('Help'))
          vim.keymap.set('n', 'v', nvimTreeApi.node.open.vertical,
            opts('Open: Vertical Split'))
          vim.keymap.set('n', '<CR>', nvimTreeApi.node.open.no_window_picker, opts('Open'))
          vim.keymap.set('n', 'o', nvimTreeApi.node.open.no_window_picker, opts('Open'))
          vim.keymap.set('n', 'O', nvimTreeApi.node.open.no_window_picker,
            opts('Open: Window Picker'))
        end
      })

      local wk = require('which-key')
      wk.register({
        d = {
          name = 'File Tree Operations (NvimTree)',
          d = { '<cmd>NvimTreeToggle<cr>', 'Toggle' },
          f = { '<cmd>NvimTreeFindFile!<cr>', 'File Tree (current file)' },
          R = { function() api.tree.toggle({ path = vim.fn.expand('/') }) end, 'Find File (root)' },
          D = { function() api.tree.toggle({ path = vim.fn.expand('$HOME') }) end, 'Find File (Home)' },
          c = { change_root_to_global_cwd, 'Change Root To Global CWD' },
          s = { ':NvimTreeFocus<CR>', 'Focus on NvimTree' },
          -- n = { vim.cmd('Explore'), 'Netrw' }
        }
      }, { prefix = '<leader>' })

      -- Allow for LSP refactors etc to work from the tree
      require('lsp-file-operations').setup()
    end,
  },
}

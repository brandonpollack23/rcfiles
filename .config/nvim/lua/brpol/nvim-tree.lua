local function change_root_to_global_cwd()
  local api = require('nvim-tree.api')
  local global_cwd = vim.fn.getcwd(-1, -1)
  api.tree.change_root(global_cwd)
end

require('nvim-tree').setup({
  on_attach = function(bufnr)
    local floatPreview = require('float-preview')
    floatPreview.attach_nvimtree(bufnr)

    local function opts(desc)
      return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
    end

    local nvimTreeApi = require('nvim-tree.api')

    -- Change updatetime only in here so I don't thrash my swapdir
    -- local defaultUpdateTime = vim.o.updatetime
    -- vim.o.updatetime = 100
    -- TODO executing too soon
    -- vim.api.nvim_create_autocmd("BufLeave", {
    --   pattern = "*",
    --   once = true,
    --   callback = function() vim.o.updatetime = defaultUpdateTime end
    -- })

    -- Run Default first
    nvimTreeApi.config.mappings.default_on_attach(bufnr)
    vim.keymap.set('n', '<C-c>', change_root_to_global_cwd, opts('Change Root To Global CWD'))
    vim.keymap.set('n', '?', nvimTreeApi.tree.toggle_help, opts('Help'))
    vim.keymap.set('n', 'v', nvimTreeApi.node.open.vertical, opts('Open: Vertical Split'))
    vim.keymap.set('n', '<CR>', nvimTreeApi.node.open.no_window_picker, opts('Open'))
    vim.keymap.set('n', 'o', nvimTreeApi.node.open.no_window_picker, opts('Open'))
    vim.keymap.set('n', 'O', nvimTreeApi.node.open.no_window_picker, opts('Open: Window Picker'))
  end
})

-- Allow for LSP refactors etc to work from the tree
require('lsp-file-operations').setup()

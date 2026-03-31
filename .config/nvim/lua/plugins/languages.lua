vim.api.nvim_create_autocmd("FileType", {
  pattern = "prolog",
  once = true,
  callback = function()
    if vim.fn.executable("swipl") ~= 1 then
      return
    end
    vim.fn.system("swipl -g 'use_module(library(lsp_server))' -g halt 2>&1")
    if vim.v.shell_error ~= 0 then
      vim.notify("[prolog_ls] lsp_server pack not found. Run:\n  swipl pack install lsp_server", vim.log.levels.WARN)
    end
  end,
})

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        prolog_ls = {
          mason = false,
          autostart = vim.fn.executable("swipl") == 1,
        },
        elixirls = {
          autostart = false,
          mason = false,
          settings = {
            elixirLS = {
              -- Dialyzer is required for the Workspace Symbol index
              dialyzerEnabled = true,
              -- Allows ElixirLS to fetch/compile deps if needed
              fetchDeps = true,
            },
          },
        },
      },
    },
  },
}

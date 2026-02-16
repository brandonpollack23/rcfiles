return {
  {
    "mfussenegger/nvim-dap",
    opts = function()
      -- Always load .vscode/launch.json if it exists
      local vscode = require("dap.ext.vscode")
      vscode.load_launchjs(nil, {})
    end,
  },
}

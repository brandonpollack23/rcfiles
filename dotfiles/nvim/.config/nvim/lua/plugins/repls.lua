return {
  {
    "Olical/conjure",
    dependencies = { "clojure-vim/vim-jack-in" },
    -- .jank files are filetype clojure (lazy.lua), so jank uses conjure's
    -- clojure nREPL client.
    ft = { "clojure", "fennel", "python" },
    lazy = true,
    init = function()
      -- Set configuration options here
      -- Uncomment this to get verbose logging to help diagnose internal Conjure issues
      -- This is VERY helpful when reporting an issue with the project
      -- vim.g["conjure#debug"] = true

      -- Conjure maps its keys per buffer without which-key groups; label its
      -- <localleader> prefixes in those buffers only, so they don't name other
      -- plugins' localleader keys elsewhere. Groups with no keys stay hidden,
      -- so the clojure-only ones don't show in python or fennel.
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("conjure_which_key", { clear = true }),
        pattern = { "clojure", "fennel", "python" },
        callback = function(args)
          local ok, wk = pcall(require, "which-key")
          -- FileType fires again when the ft trigger loads conjure.
          if not ok or vim.b[args.buf].conjure_which_key then
            return
          end
          vim.b[args.buf].conjure_which_key = true
          local ll = "<localleader>"
          wk.add({
            buffer = args.buf,
            { ll .. "e", group = "Eval" },
            { ll .. "ec", group = "Eval, result as comment" },
            { ll .. "l", group = "Log" },
            { ll .. "g", group = "Go to" },
            { ll .. "c", group = "Connection" },
            { ll .. "ca", group = "Auto REPL" },
            { ll .. "s", group = "Session" },
            { ll .. "t", group = "Test" },
            { ll .. "r", group = "Refresh" },
            { ll .. "v", group = "View" },
            { ll .. "x", group = "Macro expand" },
          })
        end,
      })
    end,
  },
  {
    "clojure-vim/vim-jack-in",
    dependencies = {
      "tpope/vim-dispatch",
      "radenling/vim-dispatch-neovim",
    },
  },
  -- LazyVim completes with blink.cmp, not nvim-cmp: blink.compat provides the
  -- `cmp` module cmp-conjure registers its source with.
  {
    "saghen/blink.cmp",
    optional = true,
    dependencies = { "saghen/blink.compat", "PaterJason/cmp-conjure" },
    opts = { sources = { compat = { "conjure" } } },
  },
}

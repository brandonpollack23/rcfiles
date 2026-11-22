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
            { ll .. "w", group = "Wrap" },
            { ll .. "w[", group = "Wrap in [ ]" },
            { ll .. "w{", group = "Wrap in { }" },
          })
        end,
      })

      -- <localleader>et: show the type of the symbol under the cursor.
      -- Clojure's ftplugin adds - / . ? ! etc. to iskeyword, so <cword> grabs
      -- whole symbols like my-var, str/join or java.util.Random.
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("conjure_eval_type", { clear = true }),
        pattern = "clojure",
        callback = function(args)
          vim.keymap.set("n", "<localleader>et", function()
            local word = vim.fn.expand("<cword>")
            if word == "" then
              return
            end
            vim.cmd("ConjureEval (type " .. word .. ")")
          end, { buffer = args.buf, desc = "Type of word" })
        end,
      })
    end,
  },
  -- Wrap keys mirror Conjure's eval scopes: <localleader>we the current form,
  -- wr the root form, ww the element under the cursor. Uppercase inserts at
  -- the tail instead of the head; w[ and w{ wrap in a vector or map.
  {
    "julienvincent/nvim-paredit",
    opts = function(_, opts)
      local paredit = require("nvim-paredit")
      local el = paredit.wrap.wrap_element_under_cursor
      local form = paredit.wrap.wrap_enclosing_form_under_cursor
      -- paredit has no root-form wrap: jump to the top-level form's head and
      -- wrap the element there.
      local function root(open, close)
        paredit.api.move_to_top_level_form_head()
        return el(open, close)
      end

      local function wrap(fn, open, close, placement)
        return function()
          paredit.cursor.place_cursor(fn(open, close), { placement = placement, mode = "insert" })
        end
      end

      local ll = "<localleader>w"
      local keys = {}
      for key, t in pairs({ e = { form, "form" }, r = { root, "root form" }, w = { el, "element" } }) do
        local fn, what = t[1], t[2]
        keys[ll .. key] = { wrap(fn, "( ", ")", "inner_start"), "Wrap " .. what .. ", insert head" }
        keys[ll .. key:upper()] = { wrap(fn, "(", ")", "inner_end"), "Wrap " .. what .. ", insert tail" }
        keys[ll .. "[" .. key] = { wrap(fn, "[", "]", "inner_start"), "Wrap " .. what .. " in [ ]" }
        keys[ll .. "{" .. key] = { wrap(fn, "{", "}", "inner_start"), "Wrap " .. what .. " in { }" }
      end
      opts.keys = vim.tbl_extend("force", opts.keys or {}, keys)
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

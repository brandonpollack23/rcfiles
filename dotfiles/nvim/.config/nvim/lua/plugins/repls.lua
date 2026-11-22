-- The runtime type of the var under the cursor, from the REPL Conjure is
-- connected to: shown in K's hover float and by <localleader>et.
local clojure_type = {}

-- JVM Clojure and babashka: the lookup uses resolve and Throwable, which
-- ClojureScript and jank (also filetype clojure) don't have.
function clojure_type.supported()
  local ext = vim.fn.expand("%:e")
  return vim.bo.filetype == "clojure" and ext ~= "cljs" and ext ~= "jank"
end

local function connected()
  local ok, server = pcall(require, "conjure.client.clojure.nrepl.server")
  return ok and server["connected?"]()
end

-- Looks the symbol up rather than evaluating it, so locals, unknown symbols,
-- macros and keywords give nil or a label instead of a compile error.
function clojure_type.code(word)
  local name = word:gsub("\\", "\\\\"):gsub('"', '\\"')
  return ([[(try (let [v (resolve (symbol "%s"))]
  (cond (var? v) (cond (:macro (meta v)) "macro" (fn? @v) "fn" :else (pr-str (type @v)))
        (class? v) "class"))
  (catch Throwable _ nil))]]):format(name)
end

-- Calls cb with the type of word, or nil when there's none, no REPL, or the
-- REPL takes longer than a second.
function clojure_type.type_of(word, cb)
  if word == "" or not clojure_type.supported() or not connected() then
    return cb(nil)
  end
  local done, value = false, nil
  local function finish(result)
    if not done then
      done = true
      vim.schedule(function()
        cb(result)
      end)
    end
  end
  -- The client's eval-str, not conjure.eval's: that one also records the
  -- request as the previous evaluation, which <localleader>ep would rerun.
  require("conjure.client.clojure.nrepl.action")["eval-str"]({
    origin = "type",
    code = clojure_type.code(word),
    context = require("conjure.extract").context(),
    ["passive?"] = true,
    cb = function(resp)
      value = resp.value or value
      if resp.status and resp.status.done then
        -- The value is printed, with a trailing newline: "\"macro\"\n".
        finish(value and vim.trim(value):match('^"(.*)"$'))
      end
    end,
  })
  vim.defer_fn(function()
    finish(nil)
  end, 1000)
end

-- LSP hover with the REPL type appended. Without a hover-capable server it
-- falls back to Conjure's doc lookup, Conjure's own K.
function clojure_type.hover()
  local preview = vim.b.lsp_floating_preview
  if preview and vim.api.nvim_win_is_valid(preview) then
    return vim.api.nvim_set_current_win(preview)
  end
  local buf = vim.api.nvim_get_current_buf()
  if #vim.lsp.get_clients({ bufnr = buf, method = "textDocument/hover" }) == 0 then
    return require("conjure.eval")["doc-word"]()
  end

  local hover, typ, pending = {}, nil, 2
  local function show()
    pending = pending - 1
    if pending > 0 or vim.api.nvim_get_current_buf() ~= buf then
      return
    end
    local lines = hover
    -- A fn's class name says nothing the hover's arglists don't.
    if typ and typ ~= "fn" then
      if #lines > 0 then
        table.insert(lines, "---")
      end
      table.insert(lines, "**type** `" .. typ .. "`")
    end
    if #lines == 0 then
      return vim.notify("No information available", vim.log.levels.INFO)
    end
    vim.lsp.util.open_floating_preview(lines, "markdown", { focus_id = "textDocument/hover" })
  end

  vim.lsp.buf_request_all(buf, "textDocument/hover", function(client)
    return vim.lsp.util.make_position_params(0, client.offset_encoding)
  end, function(results)
    for _, resp in pairs(results) do
      local contents = resp.result and resp.result.contents
      local md = contents and vim.lsp.util.convert_input_to_markdown_lines(contents) or {}
      if #md > 0 then
        if #hover > 0 then
          table.insert(hover, "---")
        end
        vim.list_extend(hover, md)
      end
    end
    show()
  end)
  clojure_type.type_of(vim.fn.expand("<cword>"), function(result)
    typ = result
    show()
  end)
end

-- The filetypes nvim-paredit supports.
local lisp_filetypes = { "clojure", "fennel", "scheme", "lisp", "janet" }

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
            -- ClojureScript and jank get the plain (type word).
            local code = clojure_type.supported() and clojure_type.code(word) or ("(type " .. word .. ")")
            require("conjure.eval")["eval-str"]({ origin = "type", code = code })
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
  -- K in Clojure buffers adds the REPL's type of the word to the LSP hover
  -- (clojure_type.hover above). It replaces the K every server gets,
  -- since any client attaching (copilot too) maps that over Conjure's K.
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      local all = opts.servers["*"] or {}
      opts.servers["*"] = all
      all.keys = all.keys or {}
      table.insert(all.keys, {
        "K",
        function()
          if vim.bo.filetype == "clojure" then
            return clojure_type.hover()
          end
          return vim.lsp.buf.hover()
        end,
        desc = "Hover",
      })
    end,
  },
  -- In Lisps, typing an opener always inserts its closer: LazyVim skips the
  -- pair when the next character is a word, [ or ", but here that's what
  -- slurping is for. Strings still get a bare opener, and ' and ` (quote and
  -- syntax quote) don't pair at all.
  {
    "nvim-mini/mini.pairs",
    config = function(_, opts)
      local pairs = require("mini.pairs")
      local raw_open = pairs.open
      LazyVim.mini.pairs(opts)
      local lazy_open = pairs.open

      local function in_string()
        local cursor = vim.api.nvim_win_get_cursor(0)
        local ok, captures = pcall(vim.treesitter.get_captures_at_pos, 0, cursor[1] - 1, math.max(cursor[2] - 1, 0))
        for _, capture in ipairs(ok and captures or {}) do
          if vim.tbl_contains(opts.skip_ts or {}, capture.capture) then
            return true
          end
        end
        return false
      end

      pairs.open = function(pair, neigh_pattern)
        if vim.tbl_contains(lisp_filetypes, vim.bo.filetype) and vim.fn.getcmdline() == "" and not in_string() then
          return raw_open(pair, neigh_pattern)
        end
        return lazy_open(pair, neigh_pattern)
      end
    end,
    -- In init, not config: mini.pairs loads on VeryLazy, after FileType has
    -- fired for a file opened from the command line.
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("lisp_quote_no_pair", { clear = true }),
        pattern = lisp_filetypes,
        callback = function(args)
          for _, quote in ipairs({ "'", "`" }) do
            vim.keymap.set("i", quote, quote, { buffer = args.buf })
          end
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

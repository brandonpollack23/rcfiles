-- Common Lisp in nvim: swank.nvim (its keys under <localleader>), with fixes
-- for nvim 0.12, buffer packages, package-qualified symbols and SBCL source
-- locations; Conjure-style eval keys; and the ASDF project of every Lisp
-- buffer loaded into the connected Lisp, so go to definition, xref and
-- completion see it without loading anything by hand.
--
-- M.spec holds the plugin specs; plugins/repls.lua includes it.
local M = {}

-- Its connect callback calls vim.notify inside libuv's callback, which nvim
-- 0.12 refuses (E5560) before the socket is read, so it connected but never
-- got a reply. Runs the callback on the main loop.
local function fix_connect()
  local Transport = require("swank.transport").Transport
  local connect = Transport.connect
  function Transport:connect(host, port, on_connect)
    return connect(self, host, port, vim.schedule_wrap(on_connect))
  end
end

-- The package named by the last (in-package ...) above the cursor in a lisp
-- buffer, or nil. Upcased unless written as a string, as the reader would.
local function buffer_package()
  if vim.bo.filetype ~= "lisp" then
    return nil
  end
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(0, 0, row, false)
  for i = #lines, 1, -1 do
    local name = lines[i]:match("^%s*%(%s*[iI][nN]%-[pP][aA][cC][kK][aA][gG][eE]%s+([^%s%)]+)")
    if name then
      return name:match('^"(.*)"$') or name:gsub("^#?:", ""):upper()
    end
  end
end

-- swank.nvim sends every request in one global package (CL-USER unless set
-- by hand), so symbols in a file's own package aren't found. Uses the
-- buffer's in-package when a request doesn't name one, as SLIME does.
local function fix_package()
  local client = require("swank.client")
  local rex = client.rex
  function client.rex(form, cb, pkg, thread)
    return rex(form, cb, pkg or buffer_package(), thread)
  end
end

-- swank.nvim sends any string that looks like pkg:sym as a bare symbol, so
-- a symbol name argument such as "uiop:getenv" (go to definition, describe,
-- eval word) reaches Swank as a symbol and fails with a reader error. Only a
-- list's head, the Swank function called, is meant as a symbol: quotes the
-- rest.
local function fix_symbol_args()
  local protocol = require("swank.protocol")
  local serialize = protocol.serialize
  local function ser(val, head)
    if type(val) == "string" and not head and val:find(":", 2, true) then
      return '"' .. val:gsub("\\", "\\\\"):gsub('"', '\\"') .. '"'
    elseif type(val) == "table" then
      local parts = {}
      for i, v in ipairs(val) do
        parts[i] = ser(v, i == 1)
      end
      return "(" .. table.concat(parts, " ") .. ")"
    end
    return serialize(val)
  end
  function protocol.serialize(val)
    return ser(val, false)
  end
end

-- The 1-based line holding 1-based character pos in file, or nil.
local function line_of_position(file, pos)
  local f = io.open(file, "rb")
  if not f then
    return nil
  end
  local text = f:read("*a")
  f:close()
  -- Swank counts characters; Lua strings are bytes.
  local ok, byte = pcall(vim.str_byteindex, text, "utf-32", pos - 1, false)
  local prefix = text:sub(1, ok and byte or pos - 1)
  return select(2, prefix:gsub("\n", "")) + 1
end

-- Adds (:line N) to a Swank location that has only SBCL's (:position N), and
-- (:file F) to one that has only (:buffer-and-file B F).
local function add_line(loc)
  local file, pos, has_file, has_line
  for _, part in ipairs(loc) do
    if type(part) == "table" then
      local tag = tostring(part[1] or ""):lower()
      if tag == ":file" then
        file, has_file = tostring(part[2]), true
      elseif tag == ":buffer-and-file" then
        file = tostring(part[3])
      elseif tag == ":position" then
        pos = tonumber(part[2])
      elseif tag == ":line" then
        has_line = true
      end
    end
  end
  if not file then
    return
  end
  if not has_file then
    table.insert(loc, { ":file", file })
  end
  if pos and not has_line then
    local line = line_of_position(file, pos)
    if line then
      table.insert(loc, { ":line", line })
    end
  end
end

-- SBCL gives source locations as character offsets, but swank.nvim's xref
-- UI (go to definition, xref, frame source) reads only line numbers and
-- otherwise jumps to line 1. Adds the lines before the UI sees them.
local function fix_locations()
  local xref = require("swank.ui.xref")
  local show = xref.show
  local function walk(node)
    if type(node) ~= "table" then
      return
    end
    if tostring(node[1] or ""):lower() == ":location" then
      return add_line(node)
    end
    for _, child in ipairs(node) do
      walk(child)
    end
  end
  function xref.show(result, kind)
    walk(result)
    return show(result, kind)
  end
end

-- The .asd file of the ASDF project holding buf's file: the nearest directory
-- above it with one, preferring the .asd named after that directory. Nil
-- outside a project.
local function project_asd(buf)
  local file = vim.api.nvim_buf_get_name(buf)
  if file == "" then
    return nil
  end
  local found = vim.fs.find(function(name)
    return name:match("%.asd$") ~= nil
  end, { upward = true, path = vim.fs.dirname(file), stop = vim.uv.os_homedir(), type = "file", limit = 1 })[1]
  if not found then
    return nil
  end
  local dir = vim.fs.dirname(found)
  local preferred = dir .. "/" .. vim.fs.basename(dir) .. ".asd"
  return vim.uv.fs_stat(preferred) and preferred or found
end

-- The .asd files loaded, or being loaded, into the current connection.
local loaded_asds = {}

-- Loads the system an .asd file is named after, with its dependencies, into
-- the connected Lisp, once per connection unless force: what you'd otherwise
-- do by hand before go to definition, xref, describe or completion can see
-- the project. Uses Quicklisp when the image has it, to fetch dependencies.
function M.load_project(buf, force)
  local client = require("swank.client")
  local asd = project_asd(buf)
  if not asd or not client.is_connected() or (loaded_asds[asd] and not force) then
    return
  end
  loaded_asds[asd] = true
  local name = vim.fn.fnamemodify(asd, ":t:r")
  local path = asd:gsub("\\", "\\\\"):gsub('"', '\\"')
  local code = ([[(let ((asd (pathname "%s")))
  (pushnew (make-pathname :name nil :type nil :defaults asd) asdf:*central-registry* :test #'equal)
  (asdf:load-asd asd)
  (let ((name (pathname-name asd)))
    (if (find-package "QUICKLISP-CLIENT")
        (uiop:symbol-call "QUICKLISP-CLIENT" "QUICKLOAD" name :silent t)
        (asdf:load-system name))
    name))]]):format(path)
  vim.notify("swank.nvim: loading " .. name .. "…", vim.log.levels.INFO)
  client.rex({ "swank:eval-and-grab-output", code }, function(result)
    if type(result) == "table" and result[1] == ":ok" then
      vim.notify("swank.nvim: loaded " .. name, vim.log.levels.INFO)
    else
      loaded_asds[asd] = nil
      vim.notify("swank.nvim: loading " .. name .. " failed", vim.log.levels.ERROR)
    end
  end, "COMMON-LISP-USER")
end

-- Loads each open Lisp buffer's project on every new connection.
local function fix_project_loading()
  local client = require("swank.client")
  local on_connect = client._on_connect
  function client._on_connect(...)
    loaded_asds = {}
    on_connect(...)
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == "lisp" then
        M.load_project(buf)
      end
    end
  end
end

-- The text of the innermost list around the cursor, or nil outside one.
local function current_form(buf)
  local node = vim.treesitter.get_node({ lang = "commonlisp" })
  while node and node:type() ~= "list_lit" do
    node = node:parent()
  end
  return node and vim.treesitter.get_node_text(node, buf)
end

-- ee evaluates the form around the cursor, er the top-level one and ew the
-- word under it, as in Conjure (swank.nvim's own ee is the top-level form).
-- ls reloads the buffer's ASDF system.
local function buffer_keys(buf)
  local client = require("swank.client")
  local function map(lhs, fn, desc)
    vim.keymap.set("n", "<localleader>" .. lhs, fn, { buffer = buf, desc = desc })
  end
  map("ee", function()
    local form = current_form(buf)
    if form then
      client.eval_replay(form)
    end
  end, "Eval current form")
  map("er", client.eval_toplevel, "Eval root form")
  map("ew", function()
    client.eval_replay(vim.fn.expand("<cword>"))
  end, "Eval word")
  map("ls", function()
    M.load_project(buf, true)
  end, "Load project's ASDF system")
end

-- swank.nvim's setup with the fixes above, and on every Lisp buffer it
-- attaches to, the extra keys and its project loaded.
function M.setup(opts)
  local swank = require("swank")
  swank.setup(opts)
  fix_connect()
  fix_package()
  fix_symbol_args()
  fix_locations()
  fix_project_loading()
  local attach = swank.attach
  swank.attach = function(buf)
    attach(buf)
    buffer_keys(buf)
    M.load_project(buf)
  end
end

M.spec = {
  {
    "corigne/swank.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    ft = "lisp",
    opts = { leader = "<localleader>", ui = { repl = { position = "bottom", size = 20 } } },
    config = function(_, opts)
      M.setup(opts)
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "commonlisp" } },
  },
  -- Swank completion.
  {
    "saghen/blink.cmp",
    optional = true,
    opts = {
      sources = {
        per_filetype = { lisp = { inherit_defaults = true, "swank" } },
        providers = {
          swank = {
            name = "Swank",
            module = "swank.sources.blink",
          },
        },
      },
    },
  },
}

return M

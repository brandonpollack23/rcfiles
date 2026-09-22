-- Run inside a headless nvim with the user config loaded:
--   nvim --headless "+luafile scripts/lib/mason-install.lua"
-- Installs every Mason package LazyVim would install on first interactive
-- launch (mason.nvim ensure_installed + Mason-backed lspconfig servers),
-- blocks until done, and exits non-zero if any install fails.

require("lazy").load({ plugins = { "mason.nvim", "mason-lspconfig.nvim" } })
local registry = require("mason-registry")
local mappings = require("mason-lspconfig").get_mappings().lspconfig_to_package

registry.refresh() -- blocking when called without a callback

local wanted = {}
for _, name in ipairs(LazyVim.opts("mason.nvim").ensure_installed or {}) do
  wanted[name] = true
end
for server, sopts in pairs(LazyVim.opts("nvim-lspconfig").servers or {}) do
  -- Same filtering LazyVim applies: skip disabled servers and mason = false.
  sopts = sopts == true and {} or sopts or { enabled = false }
  local pkg = mappings[server]
  if pkg and sopts.enabled ~= false and sopts.mason ~= false then
    wanted[pkg] = true
  end
end

local failed, pending = {}, {}
for name in pairs(wanted) do
  local ok, pkg = pcall(registry.get_package, name)
  if not ok then
    table.insert(failed, name .. " (not in registry)")
  elseif not pkg:is_installed() then
    table.insert(pending, pkg)
    -- LazyVim's mason config may already have started this install.
    if not pkg:is_installing() then
      io.stdout:write("installing " .. name .. "\n")
      pkg:install({}, function(success, err)
        if not success then
          io.stderr:write(name .. ": " .. tostring(err) .. "\n")
        end
      end)
    end
  end
end

vim.wait(30 * 60 * 1000, function()
  for _, pkg in ipairs(pending) do
    if pkg:is_installing() then
      return false
    end
  end
  return true
end, 500)

for _, pkg in ipairs(pending) do
  if not pkg:is_installed() then
    table.insert(failed, pkg.name)
  end
end

if #failed > 0 then
  io.stderr:write("mason install failed:\n  " .. table.concat(failed, "\n  ") .. "\n")
  vim.cmd("1cq")
end
vim.cmd("qa")

require('brpol')

local status_ok = pcall(require, 'local')
if not status_ok then
  vim.notify('No local vim config for this machine', vim.log.levels.TRACE)
end

require('brpol')

local status_ok, local_module = pcall(require, 'local')
if not status_ok then
  print('No defined module named \"local\", check '
    .. vim.fn.expand('%:h/lua')
    .. ' for a local module if you would like to add one for this machine')
end

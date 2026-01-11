local M = {}
DarkMode = 'dark'
function M.toggleDarkMode()
  if DarkMode == 'dark' then
    DarkMode = 'light'
  else
    DarkMode = 'dark'
  end

  vscode.load(DarkMode)
end

return M

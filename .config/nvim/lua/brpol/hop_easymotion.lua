local hop = require('hop')
local directions = require('hop.hint').HintDirection
local positions = require('hop.hint').HintPosition

vim.keymap.set('n', '<leader><leader>w', function()
  hop.hint_words({ direction = directions.AFTER_CURSOR })
end, {remap=true})

vim.keymap.set('n', '<leader><leader>e', function()
  hop.hint_words({ direction = directions.AFTER_CURSOR, hint_position = positions.END })
end, {remap=true})

vim.keymap.set('n', '<leader><leader>b', function()
  hop.hint_words({ direction = directions.BEFORE_CURSOR })
end, {remap=true})

vim.keymap.set('n', '<leader><leader>j', function()
  hop.hint_vertical({ direction = directions.AFTER_CURSOR })
end, {remap=true})

vim.keymap.set('n', '<leader><leader>k', function()
  hop.hint_vertical({ direction = directions.BEFORE_CURSOR })
end, {remap=true})

vim.keymap.set('n', '<leader><leader>f', function()
  hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = true })
end, {remap=true})

vim.keymap.set('n', '<leader><leader>F', function()
  hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = true })
end, {remap=true})

vim.keymap.set('n', '<leader><leader>t', function()
  hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = true, hint_offset = -1 })
end, {remap=true})

vim.keymap.set('n', '<leader><leader>T', function()
  hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = true, hint_offset = 1 })
end, {remap=true})

hop.setup({
  quit_key = '<SPC>',
  multi_windows = true,
})

-- Color configuration
vim.cmd('hi HopNextKey guifg=White')
vim.cmd('hi HopNextKey guibg=Red')
vim.cmd('hi HopNextKey1 guifg=White')
vim.cmd('hi HopNextKey1 guibg=Red')
vim.cmd('hi HopNextKey2 guifg=White')
vim.cmd('hi HopNextKey2 guifg=Red')

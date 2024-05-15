-- Note that this assumes chocolatey is what installed sqlite
vim.fn.setenv('HOME', os.getenv('userprofile'))
vim.g.sqlite_clib_path = [[C:\ProgramData\chocolatey\lib\SQLite\tools\sqlite3.dll]]
vim.g.neovide_cursor_animation_length = 0.0
vim.g.neovide_cursor_trail_size = 0.0
vim.g.neovide_scroll_animation_length = 0.0

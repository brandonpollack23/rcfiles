-- Note that this assumes chocolatey is what installed sqlite
vim.fn.setenv('HOME', os.getenv('userprofile'))
vim.g.sqlite_clib_path = [[C:\ProgramData\chocolatey\lib\SQLite\tools\sqlite3.dll]]

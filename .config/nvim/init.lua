require('brpol')

-- Silently try to load local config without any message if it doesn't exist
pcall(require, 'local')

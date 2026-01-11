-- Sort comma seperated list inside selection
vim.api.nvim_create_user_command('Sortcommaseperatedlist',
  [[s/\%V.*/\=join(sort(split(submatch(0), ',')), ',')]],
  {
    range = '%', -- Apply on the current visual selection
  }
)

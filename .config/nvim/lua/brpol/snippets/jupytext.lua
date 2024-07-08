-- Snippets
local luasnip = require('luasnip')
local extras = require('luasnip.extras')
local s = luasnip.snippet
local t = luasnip.text_node
local i = luasnip.insert_node
local c = luasnip.choice_node
local f = luasnip.function_node
local fmt = require('luasnip.extras.fmt').fmt
local rep = extras.rep


-- luasnip.add_snippets('lua', {
--   s('vimlog',
--     fmt([[
--     vim.notify('{}', vim.log.levels.{})
--     ]], { i(1), c(2, { t('INFO'), t('WARN'), t('ERROR'), t('TRACE'), t('DEBUG') }) })
--   ),
--   s('vimlogopt',
--     fmt([[
--     vim.notify('{}', vim.log.levels.{}, {})
--     ]], { i(1), c(2, { t('INFO'), t('WARN'), t('ERROR'), t('TRACE'), t('DEBUG') }), i(3) })
--   )
-- })
luasnip.add_snippets('python', {
  -- Insert cell delimiter at the beginning of the line and then move to the next line
  s('cdm', {
    t({
      "",
      "# %%",
      "",
      "",
    }),
    i(0),
  }),
  -- Markdown cell delimiter
  s('cdmm', {
    t({
      "",
      "# %% [markdown]",
      '"""',
      "",
    }),
    i(0),
    t({
      "",
      '"""',
      "",
      "",
    }),
  }),
})

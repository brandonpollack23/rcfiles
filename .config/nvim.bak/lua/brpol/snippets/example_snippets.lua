local luasnip = require('luasnip')
local extras = require('luasnip.extras')
local s = luasnip.snippet
local t = luasnip.text_node
local i = luasnip.insert_node
local c = luasnip.choice_node
local fmt = require('luasnip.extras.fmt').fmt
local rep = extras.rep

-- There are even more, function nodes, choice nodes, dynamic nodes, etc. https://github.com/L3MON4D3/LuaSnip/blob/master/DOC.md

-- insert_node is for tabbing between placeholders in the order specified, 0 means where to go when done.

luasnip.add_snippets('lua', {
  s('hello', {
    i(0),
    t("print('Hello, "),
    i(1, 'cruel'), -- defaults can be done by passing as strings.
    t(' '),
    i(2, 'world'),
    t('!')
  }),
  s('repeat_example', {
    t('<'), i(1), t('>'),
    t('</'), rep(1), t('>')
  }),
  s('format_example',
    -- Curlies are where things go, like rust, Double curly is escaped curly.
    fmt([[
\begin{{{}}}
  {}
\end{{{}}}
    ]], { i(1), i(2), rep(1)
    })
  ),
  s('log',
    -- 'This is a choice node, it is useful when you often choose between stuff, like debug, here is a real thing I can use.
    fmt([[
    vim.notify('{}', vim.log.levels.{})
    ]], { i(1), c(2, { t('INFO'), t('WARN'), t('ERROR'), t('TRACE'), t('DEBUG') }) })
  )
})

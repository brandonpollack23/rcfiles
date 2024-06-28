local luasnip = require('luasnip')
local s = luasnip.snippet
local t = luasnip.text_node
local i = luasnip.insert_node

-- insert_node is for tabbing between placeholders in the order specified, 0 means where to go when done.

luasnip.add_snippets('lua', {
  s('hello', {
    i(0),
    t("print('Hello, "),
    i(1),
    t(' '),
    i(2),
  }),
})

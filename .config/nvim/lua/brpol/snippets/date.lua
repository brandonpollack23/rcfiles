local luasnip = require('luasnip')
local extras = require('luasnip.extras')
local s = luasnip.snippet
local t = luasnip.text_node
local i = luasnip.insert_node
local c = luasnip.choice_node
local f = luasnip.function_node
local d = luasnip.dynamic_node
local fmt = require('luasnip.extras.fmt').fmt
local rep = extras.rep

local function unixtime()
  return os.date('%s')
end

local function dateymd()
  return os.date('%Y/%m/%d')
end

local function datedmy()
  return os.date('%d/%m/%Y')
end

luasnip.add_snippets('all', {
  s({
    trig = 'unixtime',
    desc = 'time in ms since 1970'
  }, {
    f(unixtime)
  }),
  s('dateymd', {
    f(dateymd)
  }),
  s('datedmy', {
    f(datedmy)
  }),
})

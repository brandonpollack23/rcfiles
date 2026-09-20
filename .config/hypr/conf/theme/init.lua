-- Theme manager, split across conf/theme/:
--
--   palette.lua  the active palette and the colour maths (rgba, mix, gradient)
--   select.lua   the picker, persisting the choice, cycling
--   state.lua    the chosen id on disk, which both of those need
--
-- This module owns the palette: the rest of the config asks it for colours by
-- name where it sets the option, e.g.
--
--   local theme = require("conf.theme")
--   theme.colors.primary            --> "#33ccff"
--   theme.rgba("primary", 0.9)      --> "rgba(33ccffe6)"
--
-- Pick one with scripts/theme-select.sh.

local palette = require("conf.theme.palette")
local select = require("conf.theme.select")

local M = {}

-- The active palette
M.id = palette.id
M.colors = palette.colors

-- Colour maths
M.rgba = palette.rgba
M.mix = palette.mix
M.gradient = palette.gradient
M.tabGradient = palette.tabGradient
M.list = palette.list

-- Choosing a theme
M.menu = select.menu
M.select = select.select
M.cycle = select.cycle

return M

-- The active palette and the colour maths the rest of the config asks for.
--
-- Each file in conf/themes/ returns a palette table; the selected one falls back
-- to themes/default.lua key by key, so a theme only has to name what it changes.
-- Everything here is read at config-load time, which is why selecting a theme
-- (select.lua) reloads the config.

local state = require("conf.theme.state")

local M = {}

M.FALLBACK = "default"

-- This file is conf/theme/palette.lua, so the themes sit one directory up.
local here = debug.getinfo(1, "S").source:match("^@(.*)/[^/]+$")
local themesDir = here:match("^(.*)/[^/]+$") .. "/themes"

function M.load(id)
	local chunk = loadfile(themesDir .. "/" .. id .. ".lua")
	if not chunk then
		return nil
	end
	local ok, palette = pcall(chunk)
	if ok and type(palette) == "table" then
		return palette
	end
end

-- Theme ids (file names without .lua), sorted, default first.
function M.list()
	local ids = {}
	local ls = io.popen("ls -1 '" .. themesDir .. "'")
	if ls then
		for file in ls:lines() do
			local id = file:match("^(.+)%.lua$")
			if id and id ~= M.FALLBACK then
				table.insert(ids, id)
			end
		end
		ls:close()
	end
	table.sort(ids)
	table.insert(ids, 1, M.FALLBACK)
	return ids
end

-- The name a theme shows in the picker.
function M.displayName(id)
	local palette = M.load(id)
	return palette and palette.name or id
end

-- Colour maths ----------------------------------------------------------------

-- "rgba(rrggbbaa)" from a palette key or a "#rrggbb" string; alpha is 0..1.
function M.rgba(color, alpha)
	local hex = (M.colors[color] or color):gsub("^#", "")
	return string.format("rgba(%s%02x)", hex, math.floor((alpha or 1) * 255 + 0.5))
end

-- "#rrggbb" blended from `color` toward `other` by t (0..1); both are palette keys
-- or "#rrggbb" strings, e.g. M.mix("primary", "#000000", 0.2) is 20% darker.
function M.mix(color, other, t)
	local a = (M.colors[color] or color):gsub("^#", "")
	local b = (M.colors[other] or other):gsub("^#", "")
	local out = {}
	for i = 1, 5, 2 do
		local x, y = tonumber(a:sub(i, i + 1), 16), tonumber(b:sub(i, i + 1), 16)
		table.insert(out, string.format("%02x", math.floor(x + (y - x) * t + 0.5)))
	end
	return "#" .. table.concat(out)
end

-- Two-colour gradient in the shape hl.config expects.
function M.gradient(from, to, alpha, angle)
	return { colors = { M.rgba(from, alpha), M.rgba(to, alpha) }, angle = angle or 45 }
end

-- Group tab: `color` darkened toward the background, glowing up from the bottom
-- edge. The groupbar ignores the angle: it stretches a vertical gradient over
-- each tab with the stops spaced evenly (max 10). The source orders them bottom
-- first, but the texture is drawn flipped, so on screen the list runs top-down.
-- From the bottom, the accent eases over `fade` stops into the tint, which is
-- `color` mixed `depth` (0..1) of the way to the background.
function M.tabGradient(color, alpha, fade, depth)
	fade = fade or 6
	local tint = M.mix(color, "background", depth or 0.5)
	local colors = { M.rgba(color) }
	for i = 1, 9 do
		local t = 1 - (1 - math.min(i / fade, 1)) ^ 2 -- ease-out
		table.insert(colors, 1, M.rgba(M.mix(color, tint, t), alpha))
	end
	return { colors = colors }
end

-- The active palette -----------------------------------------------------------

local fallback = assert(M.load(M.FALLBACK), "conf/themes/" .. M.FALLBACK .. ".lua is missing or broken")
M.id = state.read() or M.FALLBACK
local selected = M.load(M.id)
if not selected then
	M.id, selected = M.FALLBACK, fallback
end
M.colors = setmetatable(selected, { __index = fallback })

return M

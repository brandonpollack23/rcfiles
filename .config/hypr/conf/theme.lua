-- Theme manager. Each file in conf/themes/ returns a palette table; the selected
-- one (falling back to themes/default.lua key by key) is exposed as
-- `theme.colors`. This module only owns the palette: the rest of the config asks
-- it for colours by name where it sets the option, e.g.
--
--   local theme = require("conf.theme")
--   theme.colors.primary            --> "#33ccff"
--   theme.rgba("primary", 0.9)      --> "rgba(33ccffe6)"
--
-- The selection is kept outside the repo in $XDG_STATE_HOME/hypr/theme.
-- Selecting reloads the config, so everything that reads `theme.colors` at load
-- time picks up the new palette. Pick one with scripts/theme-select.sh.
local M = {}

local FALLBACK = "default"

local confDir = debug.getinfo(1, "S").source:match("^@(.*)/[^/]+$")
local themesDir = confDir .. "/themes"
local stateDir = (os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")) .. "/hypr"
local stateFile = stateDir .. "/theme"

local function loadTheme(id)
	local chunk = loadfile(themesDir .. "/" .. id .. ".lua")
	if not chunk then
		return nil
	end
	local ok, palette = pcall(chunk)
	if ok and type(palette) == "table" then
		return palette
	end
end

local function savedId()
	local f = io.open(stateFile)
	if not f then
		return FALLBACK
	end
	local id = f:read("l")
	f:close()
	return id or FALLBACK
end

-- Theme ids (file names without .lua), sorted, default first.
function M.list()
	local ids = {}
	local ls = io.popen("ls -1 '" .. themesDir .. "'")
	if ls then
		for file in ls:lines() do
			local id = file:match("^(.+)%.lua$")
			if id and id ~= FALLBACK then
				table.insert(ids, id)
			end
		end
		ls:close()
	end
	table.sort(ids)
	table.insert(ids, 1, FALLBACK)
	return ids
end

local function displayName(id)
	local palette = loadTheme(id)
	return palette and palette.name or id
end

-- Newline-separated theme names for a dmenu-style picker.
function M.menu()
	local lines = {}
	for _, id in ipairs(M.list()) do
		table.insert(lines, displayName(id))
	end
	return table.concat(lines, "\n")
end

-- Persist the theme (by id or by the name shown in the menu) and reload the config.
function M.select(choice)
	for _, id in ipairs(M.list()) do
		if id == choice or displayName(id) == choice then
			os.execute("mkdir -p '" .. stateDir .. "'")
			local f = assert(io.open(stateFile, "w"))
			f:write(id, "\n")
			f:close()
			hl.exec_cmd("hyprctl reload config-only")
			return id
		end
	end
	error("unknown theme: " .. tostring(choice))
end

-- Step through the themes, a poor man's preview since hyprlauncher cannot report
-- the highlighted row.
function M.cycle(step)
	local ids = M.list()
	for i, id in ipairs(ids) do
		if id == M.id then
			return M.select(ids[(i - 1 + (step or 1)) % #ids + 1])
		end
	end
	return M.select(FALLBACK)
end

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

local fallback = assert(loadTheme(FALLBACK), "conf/themes/" .. FALLBACK .. ".lua is missing or broken")
M.id = savedId()
local selected = loadTheme(M.id)
if not selected then
	M.id, selected = FALLBACK, fallback
end
M.colors = setmetatable(selected, { __index = fallback })

return M

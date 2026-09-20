-- Choosing a theme: the picker list, persisting the choice, and stepping
-- through the themes. Selecting reloads the config, so everything that read
-- `theme.colors` at load time picks up the new palette.
--
-- Driven by scripts/theme-select.sh and the SUPER+F6 binds.

local palette = require("conf.theme.palette")
local state = require("conf.theme.state")

local M = {}

-- Newline-separated theme names for a dmenu-style picker.
function M.menu()
	local lines = {}
	for _, id in ipairs(palette.list()) do
		table.insert(lines, palette.displayName(id))
	end
	return table.concat(lines, "\n")
end

-- Persist the theme (by id or by the name shown in the menu) and reload the config.
function M.select(choice)
	for _, id in ipairs(palette.list()) do
		if id == choice or palette.displayName(id) == choice then
			state.write(id)
			hl.exec_cmd("hyprctl reload config-only")
			return id
		end
	end
	error("unknown theme: " .. tostring(choice))
end

-- Step through the themes, a poor man's preview since hyprlauncher cannot report
-- the highlighted row.
function M.cycle(step)
	local ids = palette.list()
	for i, id in ipairs(ids) do
		if id == palette.id then
			return M.select(ids[(i - 1 + (step or 1)) % #ids + 1])
		end
	end
	return M.select(palette.FALLBACK)
end

return M

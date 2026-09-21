-- Named workspaces, split across conf/workspaces/:
--
--   picker.lua  the picker and naming prompts (scripts/workspace-menu.sh)
--   order.lua   placement, reordering, and keeping the ids gap-free
--   ids.lua     workspace ids, their labels, and the lookups both need
--   hidden.lua  the special workspaces the picker lists as H1, H2, ...
--   layout.lua  which layout each workspace is in, focus or work/reference
--   persist.lua getting names and order through a session restore
--
-- This file is the only name the rest of the config knows: keymaps.lua and
-- scripts/workspace-menu.sh come through `conf.workspaces`.

local hidden = require("conf.workspaces.hidden")
local layout = require("conf.workspaces.layout")
local order = require("conf.workspaces.order")
local persist = require("conf.workspaces.persist")
local picker = require("conf.workspaces.picker")

local M = {}

-- Picker and prompts
M.menu = picker.menu
M.newName = picker.newName
M.pick = picker.pick
M.create = picker.create
M.createHidden = picker.createHidden
M.hiddenCount = picker.hiddenCount
M.hiddenMenu = picker.hiddenMenu
M.moveToHidden = picker.moveToHidden
M.toggleHidden = hidden.toggle
function M.rename(id, name)
	picker.rename(id, name)
	persist.recordSoon()
end
M.active = picker.active

-- Layouts (conf/layouts.lua)
M.toggleLayout = layout.toggle

-- Ordering
M.positions = order.positions
function M.shift(delta)
	order.shift(delta)
	persist.recordSoon()
end
M.compact = order.compact

-- Session restore (scripts/session.sh)
M.prepareRestore = persist.prepare
M.finishRestore = persist.finish

return M

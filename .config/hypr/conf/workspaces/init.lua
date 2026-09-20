-- Named workspaces, split across conf/workspaces/:
--
--   picker.lua  the picker and naming prompts (scripts/workspace-menu.sh)
--   order.lua   placement, reordering, and keeping the ids gap-free
--   ids.lua     workspace ids, their labels, and the lookups both need
--   hidden.lua  the special workspaces the picker lists as H1, H2, ...
--
-- This file is the only name the rest of the config knows: keymaps.lua and
-- scripts/workspace-menu.sh come through `conf.workspaces`.

local hidden = require("conf.workspaces.hidden")
local order = require("conf.workspaces.order")
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
M.rename = picker.rename
M.active = picker.active

-- Ordering
M.positions = order.positions
M.shift = order.shift
M.compact = order.compact

return M

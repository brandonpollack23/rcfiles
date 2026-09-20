-- Window management, split across conf/wm/:
--
--   close.lua    closing every window on the workspace but the focused one
--   group.lua    window groups: every action that changes one
--   history.lua  undo/redo for the group actions
--   dialog.lua   the ask-then-call-back confirmation dialog both flows use
--   taskbar.lua  what waybar's per-window taskbar needs and IPC does not report
--   windows.lua  looking up windows and groups by address
--
-- This file is the only name the rest of the config knows. keymaps.lua, the
-- waybar taskbar modules and the dialog callbacks all come through `conf.wm`,
-- so the submodules can be rearranged without touching them.

local close = require("conf.wm.close")
local group = require("conf.wm.group")
local history = require("conf.wm.history")
local taskbar = require("conf.wm.taskbar")

local M = {}

-- Closing windows
M.closeOtherWindows = close.closeOthers
M.confirmCloseOtherWindows = close.confirm
M.cancelCloseOtherWindows = close.cancel

-- The taskbar, read by waybar's `custom/winN` modules
M.lockedAddresses = taskbar.lockedAddresses
M.focusAddress = taskbar.focusAddress
M.refreshTaskbar = taskbar.refresh

-- Group actions
M.toggleGroup = group.toggle
M.toggleGroupLock = group.toggleLock
M.groupWith = group.joinToward
M.ungroup = group.ungroup
M.confirmUngroup = group.confirmUngroup
M.cancelUngroup = group.cancelUngroup
M.moveInGroup = group.moveInGroup

-- Undo/redo
M.undo = history.undo
M.redo = history.redo

return M

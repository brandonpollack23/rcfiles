-- Undo/redo for the group actions.
--
-- Hyprland has no undo of its own, and the Lua API fires no event for group
-- changes, so this covers exactly what goes through the actions in
-- conf/wm/group.lua. A window dragged onto a groupbar by mouse is invisible
-- to it.
--
-- The history stores no window objects, only the pair of closures that replay
-- an action in each direction. A closure returns false when the windows it
-- needs are gone, and the entry is dropped.

local M = {}

local MAX_HISTORY = 30
local undoStack, redoStack = {}, {}

local function notify(text)
	hl.notification.create({ text = text, duration = 1500 })
end

function M.record(label, undo, redo)
	table.insert(undoStack, { label = label, undo = undo, redo = redo })
	if #undoStack > MAX_HISTORY then
		table.remove(undoStack, 1)
	end
	redoStack = {}
end

local function replay(from, to, key, verb)
	while #from > 0 do
		local action = table.remove(from)
		if action[key]() then
			table.insert(to, action)
			notify(verb .. ": " .. action.label)
			return
		end
		-- Its windows are gone; drop it and try the one before.
	end
	notify("Nothing to " .. verb:lower())
end

function M.undo()
	replay(undoStack, redoStack, "undo", "Undo")
end

function M.redo()
	replay(redoStack, undoStack, "redo", "Redo")
end

return M

-- Stepping left and right through the open workspaces, for SUPER + CTRL +
-- arrows (bindings.lua).
--
-- Like `e-1`/`e+1`, except that past the last workspace on that side a new one
-- is made, the next number over, as long as this one has windows: an empty
-- workspace is already the fresh one you'd be making. From an empty workspace,
-- or left of workspace 1, it wraps round the way `e-1`/`e+1` do.

local M = {}

-- Ids of the open workspaces, special ones left out, smallest first.
local function openIds()
  local ids = {}
  for _, workspace in ipairs(hl.get_workspaces()) do
    if not workspace.special and workspace.id > 0 then
      table.insert(ids, workspace.id)
    end
  end
  table.sort(ids)
  return ids
end

-- The closest open workspace past `id` in `step`'s direction (1 or -1), or nil.
local function neighbour(id, step)
  local found
  for _, other in ipairs(openIds()) do
    if (other - id) * step > 0 and (not found or (other - found) * step < 0) then
      found = other
    end
  end
  return found
end

-- Move one workspace in `step`'s direction: -1 left, 1 right.
function M.step(step)
  local current = hl.get_active_workspace()
  if not current or current.special then
    return
  end
  local target = neighbour(current.id, step)
  if not target and current.windows > 0 and current.id + step > 0 then
    target = current.id + step
  end
  local workspace = target and tostring(target) or (step > 0 and "e+1" or "e-1")
  hl.dispatch(hl.dsp.focus({ workspace = workspace }))
end

return M

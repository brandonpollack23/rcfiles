-- Stepping left and right through the open workspaces, for SUPER + CTRL +
-- arrows (bindings.lua), and keeping them numbered 1, 2, 3... in order: when
-- one closes the ones after it move down, one opened past the end takes the
-- next number, and a new one put between two
-- (hypr-workspace-menu new) moves the ones after it up. Their saved layouts
-- (layouts.lua) go with them.
--
-- Like `e-1`/`e+1`, except that past the last workspace on that side a new one
-- is made, the next number over, as long as this one has windows: an empty
-- workspace is already the fresh one you'd be making. From an empty workspace,
-- or left of workspace 1, it wraps round the way `e-1`/`e+1` do.

local layouts = require("hypr.layouts")

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

  -- An open GloView overview (hyprland.lua) keeps showing the workspace it was
  -- on, and goes back to it when it closes; show it the one we landed on. With
  -- the overview closed, that's already the live one and nothing happens.
  local landed = hl.get_active_workspace()
  if hl.plugin.gloview and landed then
    hl.plugin.gloview.setworkspace(landed.id)
  end
end

-- Give open workspace `from` the free id `to`. Its layout rule goes first, in
-- case the new id's rules are applied to it.
function M.renumber(from, to)
  layouts.move(tostring(from), tostring(to))
  hl.dispatch(hl.dsp.workspace.change_id({ workspace = tostring(from), id = to }))
end

-- Number the open workspaces 1, 2, 3... in the order they're in. Going up,
-- each one's new id is free: the ones below it have already moved under it.
local function compact()
  for index, id in ipairs(openIds()) do
    if id ~= index then
      M.renumber(id, index)
    end
  end
end

-- Free `id` by moving the open workspaces from it up to the next gap one id
-- up, the last first.
local function makeRoom(id)
  local open = {}
  for _, other in ipairs(openIds()) do
    open[other] = true
  end
  local last = id
  while open[last] do
    last = last + 1
  end
  for n = last - 1, id, -1 do
    M.renumber(n, n + 1)
  end
end

-- A new workspace at `id` named `name`, gone to, or with `window` the active
-- window sent there, followed when `follow` is. In one call, so the gap the
-- workspace left behind can't be closed before the new one is named.
function M.insert(id, name, window, follow)
  makeRoom(id)
  local workspace = tostring(id)
  layouts.forget(workspace)
  if window then
    hl.dispatch(hl.dsp.window.move({ workspace = workspace, follow = follow }))
  else
    hl.dispatch(hl.dsp.focus({ workspace = workspace }))
  end
  hl.dispatch(hl.dsp.workspace.rename({ workspace = workspace, name = name ~= "" and name or workspace }))
end

-- On a workspace opening too, so one made past the end (SUPER + 7 with three
-- open) becomes the next number. Deferred until the list has caught up.
local function compactSoon()
  hl.timer(compact, { timeout = 20, type = "oneshot" })
end
hl.on("workspace.removed", compactSoon)
hl.on("workspace.created", compactSoon)

return M

-- Keeps a master preset's orientation and mfact (hypr/layouts.lua) on its
-- workspace.
--
-- A workspace rule can carry the orientation but not mfact, and a `mfact`
-- layout message only reaches the focused workspace and is lost once the
-- workspace empties. So both are sent when a preset is picked, and again on a
-- workspace's first window or, if the workspace wasn't on screen then, when it
-- is next shown.

local M = {}

-- Set by layouts.lua: the preset a workspace should have, with its
-- `orientation` and `mfact` when they aren't the config's, or nil when it isn't
-- a master one.
M.presetOf = function(_)
  return nil
end

-- Workspace ids to catch up when they are next shown.
local stale = {}

-- One per layout node: a group is a single node, laid out by its front tab.
local function tiledCount(workspace)
  local count = 0
  for _, window in ipairs(hl.get_workspace_windows(workspace.id)) do
    if window.mapped and window.visible and not window.floating then
      count = count + 1
    end
  end
  return count
end

-- Send the orientation and mfact, or mark the workspace stale when a layout
-- message can't reach it now: it isn't the one on screen, an open special
-- workspace would take the message, or it has no window for the message to
-- act on. Also held off while a window is fullscreen, because the orientation
-- message takes the focused window out of it.
function M.apply(id)
  local workspace = hl.get_workspace(id)
  if not workspace then
    return
  end
  local preset = M.presetOf(workspace)
  if not preset then
    stale[id] = nil
    return
  end
  local active = hl.get_active_workspace()
  if
    not active
    or active.id ~= workspace.id
    or hl.get_active_special_workspace()
    or workspace.has_fullscreen
    or tiledCount(workspace) == 0
  then
    stale[id] = true
    return
  end
  stale[id] = nil
  local orientation = preset.orientation or hl.get_config("master.orientation")
  local mfact = preset.mfact or hl.get_config("master.mfact")
  pcall(hl.dispatch, hl.dsp.layout("orientation" .. orientation))
  pcall(hl.dispatch, hl.dsp.layout("mfact exact " .. mfact))
end

-- Deferred so a changed rule or a new window is in the layout by then. `after`
-- runs once it's sent.
function M.applySoon(id, after)
  hl.timer(function()
    M.apply(id)
    if after then
      after()
    end
  end, { timeout = 20, type = "oneshot" })
end

-- A first window gets the config's mfact, so a preset with its own is sent
-- again then.
local function arrived(workspace)
  if not workspace or workspace.special then
    return
  end
  local preset = M.presetOf(workspace)
  if not preset or not preset.mfact then
    return
  end
  local id = tostring(workspace.id)
  hl.timer(function()
    local now = hl.get_workspace(id)
    if now and tiledCount(now) == 1 then
      M.apply(id)
    end
  end, { timeout = 20, type = "oneshot" })
end

local function catchUp()
  local workspace = hl.get_active_workspace()
  if workspace and stale[tostring(workspace.id)] then
    M.applySoon(tostring(workspace.id))
  end
end

hl.on("window.open", function(window)
  arrived(window.workspace)
end)
hl.on("window.move_to_workspace", function(_, workspace)
  arrived(workspace)
end)
hl.on("workspace.active", catchUp)
hl.on("workspace.special_active", catchUp)

return M

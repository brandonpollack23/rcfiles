-- Keeps a master preset's orientation and mfact (hypr/layouts.lua) on its
-- workspace, and a dwindle preset's first split ratio.
--
-- A workspace rule can carry the orientation but not mfact, and a `mfact`
-- layout message only reaches the focused workspace and is lost once the
-- workspace empties. So both are sent when a preset is picked, and again on a
-- workspace's first window or, if the workspace wasn't on screen then, when it
-- is next shown. Special workspaces (the scratchpad) count as shown while open.
-- A dwindle ratio goes the same way, on the second window, which makes the
-- first split.

local M = {}

-- What a workspace goes by in rules and saved choices: its name for a special
-- workspace, whose id is only its slot, and its id for the rest.
function M.key(workspace)
  return workspace.special and workspace.name or tostring(workspace.id)
end

-- The workspace layout messages reach: an open special one, else the active.
function M.shown()
  return hl.get_active_special_workspace() or hl.get_active_workspace()
end

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

-- The window left of dwindle's first split, which `splitratio` has to be sent
-- from: the leftmost, and the tallest of those, as it spans the split.
local function firstLeft(workspace)
  local found
  for _, window in ipairs(hl.get_workspace_windows(workspace.id)) do
    if window.mapped and window.visible and not window.floating then
      if
        not found
        or window.at.x < found.at.x
        or (window.at.x == found.at.x and window.size.y > found.size.y)
      then
        found = window
      end
    end
  end
  return found
end

-- Send the first split's ratio from the window left of it, then give the focus
-- back.
local function applyRatio(workspace, ratio)
  local focused = hl.get_active_window()
  local left = firstLeft(workspace)
  if not left then
    return
  end
  if not focused or focused.address ~= left.address then
    hl.dispatch(hl.dsp.focus({ window = "address:" .. left.address }))
  end
  pcall(hl.dispatch, hl.dsp.layout("splitratio " .. ratio .. " exact"))
  if focused and focused.address ~= left.address then
    hl.dispatch(hl.dsp.focus({ window = "address:" .. focused.address }))
  end
end

-- Send the orientation and mfact, or the ratio, or mark the workspace stale
-- when a layout message can't reach it now: it isn't the one shown (an open
-- special workspace takes the message over the one under it), or it has no
-- window for the message to act on (no split, for the ratio). Also held off while a window is fullscreen, because the orientation
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
  local shown = M.shown()
  if
    not shown
    or shown.id ~= workspace.id
    or workspace.has_fullscreen
    or tiledCount(workspace) < (preset.ratio and 2 or 1)
  then
    stale[id] = true
    return
  end
  stale[id] = nil
  if preset.ratio then
    applyRatio(workspace, preset.ratio)
    return
  end
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

-- A first window gets the config's mfact, and a second a first split with the
-- config's ratio, so a preset with its own is sent again then.
local function arrived(workspace)
  if not workspace then
    return
  end
  local preset = M.presetOf(workspace)
  if not preset or not (preset.mfact or preset.ratio) then
    return
  end
  local id = M.key(workspace)
  local count = preset.ratio and 2 or 1
  hl.timer(function()
    local now = hl.get_workspace(id)
    if now and tiledCount(now) == count then
      M.apply(id)
    end
  end, { timeout = 20, type = "oneshot" })
end

local function catchUp()
  local workspace = M.shown()
  if workspace and stale[M.key(workspace)] then
    M.applySoon(M.key(workspace))
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

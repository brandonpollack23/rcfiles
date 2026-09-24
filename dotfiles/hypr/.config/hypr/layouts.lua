-- The layouts SUPER + ALT + L cycles a workspace through: focus (the centered master
-- from looknfeel.lua), work/reference, dwindle and scrolling.
--
-- Work/reference is master too, with the work in a wide master and the
-- reference in a narrow column beside it. layouts/master.lua keeps a master
-- preset's orientation and mfact on the workspace.
--
-- An open special workspace (the scratchpad) is cycled rather than the one
-- under it.
--
-- Each choice is saved where Omarchy's default/hypr/workspace-layouts.lua
-- loads it from on every config load, as a call to M.use below.

local paths = require("default.hypr.paths")
local master = require("hypr.layouts.master")

local M = {}

-- Share of the screen the reference column gets, and which side it is on.
local REFERENCE_WIDTH = 0.25
local REFERENCE_SIDE = "left"

M.presets = {
  focus = { label = "Default", layout = "master" },
  reference = {
    label = "Work/reference",
    layout = "master",
    -- The orientation names the side the master goes on.
    orientation = REFERENCE_SIDE == "left" and "right" or "left",
    mfact = 1 - REFERENCE_WIDTH,
  },
  dwindle = { label = "Dwindle", layout = "dwindle" },
  scrolling = { label = "Scrolling", layout = "scrolling" },
}

M.CYCLE = { "focus", "reference", "dwindle", "scrolling" }

local DIR = paths.state_home .. "/omarchy/workspace-layouts"

-- Preset keys by workspace key (master.key: the id, or a special one's name).
local chosen = {}

-- Pick a preset for a workspace: its rule, and what layouts/master.lua sends.
function M.use(id, key)
  local preset = M.presets[key]
  if not preset then
    return
  end
  chosen[id] = key
  local rule = { workspace = id, layout = preset.layout }
  if preset.orientation then
    rule.layout_opts = { orientation = preset.orientation }
  end
  hl.workspace_rule(rule)
end

local function save(id, key)
  os.execute("mkdir -p '" .. DIR .. "'")
  -- A special workspace's colon would read as part of a module name.
  local file = io.open(DIR .. "/" .. id:gsub(":", "-") .. ".lua", "w")
  if file then
    file:write(string.format('require("hypr.layouts").use("%s", "%s")\n', id, key))
    file:close()
  end
end

-- The preset a workspace is in. The saved choice unless something else changed
-- its layout since, then the first preset with the layout it has.
local function current(workspace)
  local key = chosen[master.key(workspace)]
  if key and M.presets[key].layout == workspace.tiled_layout then
    return key
  end
  for _, name in ipairs(M.CYCLE) do
    if M.presets[name].layout == workspace.tiled_layout then
      return name
    end
  end
  return M.CYCLE[1]
end

-- What layouts/master.lua keeps on a workspace in a master preset.
master.presetOf = function(workspace)
  local preset = M.presets[current(workspace)]
  if preset.layout == "master" then
    return preset
  end
end

-- SUPER + ALT + L: the shown workspace's next preset.
function M.cycle()
  local workspace = master.shown()
  if not workspace then
    return
  end
  local id = master.key(workspace)
  local from = current(workspace)
  local next = M.CYCLE[1]
  for index, key in ipairs(M.CYCLE) do
    if key == from then
      next = M.CYCLE[index % #M.CYCLE + 1]
    end
  end
  M.use(id, next)
  -- Saved only after the preset is sent: writing the file makes Hyprland
  -- reload its config, and the reload drops applySoon's pending timer.
  master.applySoon(id, function()
    save(id, next)
  end)
  hl.notification.create({ text = "Workspace layout: " .. M.presets[next].label, duration = 1500 })
end

return M

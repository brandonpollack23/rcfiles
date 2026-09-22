-- The two layouts a workspace can be in. SUPER+ALT+O flips the active workspace
-- between them, and each workspace keeps its choice by name
-- (conf/workspaces/layout.lua).
local M = {}

-- Work/reference: the master window is the work and the stack beside it is the
-- reference. Dial these in here; `hyprctl reload` puts a change on each
-- work/reference workspace the next time it is shown.
local REFERENCE_WIDTH = 0.25 -- share of the screen the reference column gets
local REFERENCE_SIDE = "left" -- "left" or "right"

M.presets = {
	-- One task in the middle, anything else in the columns either side.
	focus = { label = "Focus", orientation = "center", mfact = 0.6 },
	-- The orientation names the side the master goes on.
	reference = {
		label = "Work/reference",
		orientation = REFERENCE_SIDE == "left" and "right" or "left",
		mfact = 1 - REFERENCE_WIDTH,
	},
}

-- A new workspace starts in this one, and it is what the master config below
-- gives every workspace that nothing has changed.
M.DEFAULT = "focus"

-- See https://wiki.hypr.land/configuring/layouts/master-layout/ for more
hl.config({
	master = {
		mfact = M.presets[M.DEFAULT].mfact,
		orientation = M.presets[M.DEFAULT].orientation,
		slave_count_for_center_master = 0,

		new_status = "slave",
		always_keep_position = true,
		smart_resizing = true,
	},
})

-- See https://wiki.hypr.land/configuring/layouts/dwindle-layout/ for more
hl.config({
	dwindle = {
		preserve_split = true, -- You probably want this
	},
})

-- Hidden workspaces, the scratchpad included, tile with dwindle. The presets
-- above are master settings, so conf/workspaces/layout.lua leaves them be.
hl.workspace_rule({ workspace = "s[true]", layout = "dwindle" })

-- See https://wiki.hypr.land/configuring/layouts/scrolling-layout/ for more
hl.config({
	scrolling = {
		fullscreen_on_one_column = true,
	},
})

return M

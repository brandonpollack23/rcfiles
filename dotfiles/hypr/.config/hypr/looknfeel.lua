-- Change the default Omarchy look'n'feel.

-- Master is the default layout, with the master window centered and half the
-- screen wide even when it has no slaves yet. SUPER + ALT + L cycles a workspace
-- through master, dwindle and scrolling (see bindings.lua).
-- https://wiki.hypr.land/Configuring/Layouts/Master-Layout/
hl.config({
  general = {
    layout = "master",
  },

  master = {
    -- Slaves are dealt out right, left, right... by their place in the stack,
    -- so closing one still flips every slave after it to the other side.
    orientation = "center",
    mfact = 0.5,
    -- Center the master however few slaves there are (0 = always).
    slave_count_for_center_master = 0,
    -- New windows join the end of the stack instead of taking master (Omarchy
    -- sets "master"), so opening one doesn't shift the others either.
    new_status = "slave",
  },
})

-- https://wiki.hypr.land/Configuring/Basics/Variables/#general
hl.config({
  general = {
    -- No gaps between windows or borders.
    gaps_in = 0,
    gaps_out = 0,
    border_size = 2,
  },
})

-- https://wiki.hypr.land/Configuring/Basics/Variables/#decoration
hl.config({
  decoration = {
    -- Use round window corners.
    rounding = 8,

    -- Dim unfocused windows (0.0 = no dim, 1.0 = fully dimmed).
    dim_inactive = true,
    dim_strength = 0.05,
  },
})

-- https://wiki.hypr.land/Configuring/Basics/Variables/#animations
-- hl.config({
--   animations = {
--     -- Disable all animations.
--     enabled = false,
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#layout
-- hl.config({
--   layout = {
--     -- Avoid overly wide single-window layouts on wide screens.
--     single_window_aspect_ratio = { 1, 1 },
--   },
-- })

-- https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/
-- hl.config({
--   scrolling = {
--     -- See only one column per screen instead of two.
--     column_width = 0.97,
--   },
-- })

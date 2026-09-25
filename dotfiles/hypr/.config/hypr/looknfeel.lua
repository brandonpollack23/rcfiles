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

-- The current theme's palette, as "rrggbb" by name, read from the colors.toml
-- Omarchy writes on every theme change (which reloads Hyprland, so this rereads
-- it). Empty if the file is missing.
local function theme_colors()
  local colors = {}
  local file = io.open(os.getenv("HOME") .. "/.local/state/omarchy/current/theme/colors.toml")
  if file then
    for line in file:lines() do
      local name, hex = line:match('^%s*([%w_]+)%s*=%s*"#(%x%x%x%x%x%x)"')
      if name then
        colors[name] = hex:lower()
      end
    end
    file:close()
  end
  return colors
end

local theme = theme_colors()
local function color(name, fallback, alpha)
  return "rgba(" .. (theme[name] or fallback) .. (alpha or "ff") .. ")"
end

-- Group tabs drawn like browser tabs: the active one filled with the theme's
-- accent, the others with the selection gray, and a gap between each so they
-- read as separate tabs (Omarchy's near-transparent black hides them). A
-- locked group turns red, tabs and border, even when it isn't focused.
-- Hyprland only draws a tab as active while its window has focus, so a group
-- you've focused away from shows every tab inactive.
-- https://wiki.hypr.land/Configuring/Basics/Variables/#groupbar
hl.config({
  group = {
    col = {
      border_locked_active = color("red", "f38ba8"),
      border_locked_inactive = color("red", "f38ba8", "66"),
    },

    groupbar = {
      blur = true,
      font_size = 17,
      indicator_height = 2,
      indicator_gap = 3,
      -- Space between tabs, and none against the window below.
      gaps_in = 6,
      gaps_out = 0,

      col = {
        active = color("accent", "89b4fa"),
        inactive = color("selection", "45475a"),
        locked_active = color("red", "f38ba8"),
        locked_inactive = color("red", "f38ba8", "55"),
      },

      -- Dark text on the accent and the locked red, the normal foreground on
      -- the others.
      text_color = color("background", "1e1e2e"),
      text_color_inactive = color("foreground", "cdd6f4"),
      text_color_locked_active = color("background", "1e1e2e"),
      text_color_locked_inactive = color("foreground", "cdd6f4"),

      gradients = true,
      gradient_rounding = 4,
      gradient_round_only_edges = false,

      rounding = 4,
    },
  },
})

-- hyprfocus (loaded in hyprland.lua) bumps the window taking focus: up a few
-- pixels, then back down into place. Hyprland loads plugins after reading the
-- config and then rereads it, so this sees the plugin on that second pass.
-- Only keyboard focus changes, since focus follows the mouse and every window
-- the pointer crosses would bump too.
-- https://github.com/hyprwm/hyprland-plugins/tree/main/hyprfocus
local function plugin_loaded(name)
  for _, plugin in ipairs(hl.get_loaded_plugins()) do
    if plugin.name == name then
      return true
    end
  end
  return false
end

if plugin_loaded("hyprfocus") then
  hl.config({
    plugin = {
      hyprfocus = {
        keyboard_focus_animation = "slide",
        mouse_focus_animation = "none",
        slide_height = 8,
      },
    },
  })

  -- A quick rise, then the drop back. The window keeps hyprfocusOut for its
  -- next moves too, so that one matches Omarchy's windows animation.
  hl.animation({ leaf = "hyprfocusIn", enabled = true, speed = 1.5, bezier = "easeOutQuint" })
  hl.animation({ leaf = "hyprfocusOut", enabled = true, speed = 3.79, bezier = "easeOutQuint" })
end

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

-- >>> omaland managed block >>>
-- Written by Omaland. Safe to hand-edit: Omaland re-reads this block
-- every time it opens, and only ever rewrites what's between the fences.
hl.config({
  decoration = {
    blur = {
      enabled = true,
    },

    shadow = {
      enabled = true,
    },
  },

  general = {
    snap = {
      enabled = true,
    },
  },
})
-- <<< omaland managed block <<<

# TODO

## Features

- mozc and indicator
- unified settings app
- can volume open volume control popup panel
- can bluetooth open bluetooth control popup panel
- notification/new tab highlights workspace
- mission control like view
- work view (1/4 3/4)
- better group theming/bars alternative
- coding orientation, cycle between layouts on workspaces and save them
- kde phone connect
- hidden workspace stuff to replicate minimizing: windows I can pull up, view
  whenever and unminimize (special workspace(s))
- Bing wallpaper title and link in waybar (`scripts/bing-wallpaper.sh title` / `open`)
- ungroup command that keeps the current focus as master
- theme the file manager (`nautilus`, `conf/programs.lua`)
- popup for sound/mute
- once we have session restore, check that named workspaces
  (`conf/workspaces.lua`) are compatible with it, and whether workspace names
  can be restored across reboots too

## Disabled config snippets

Commented-out config moved out of the Lua files. Paste back in to enable. Any
program they run is listed in `DEPENDENCIES.md` under "Referenced only in
`TODO.md`".

### Autostart (`hyprland.lua`)

Inside the `hl.on("hyprland.start", ...)` callback. See
<https://wiki.hypr.land/configuring/core/autostart/>.

```lua
hl.exec_cmd("nm-applet")
hl.exec_cmd("waybar & hyprpaper & " .. programs.browser)
```

### Permissions (`hyprland.lua`)

See
<https://wiki.hypr.land/configuring/core/advanced-configuration/permissions/>.
Permission changes require a Hyprland restart and are not applied on the fly,
for security reasons.

```lua
hl.config({
 ecosystem = {
  enforce_permissions = true,
 },
})

hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")
```

### Shutdown/logout bind (`conf/keymaps.lua`)

`SUPER+M` is taken by the workspace move picker now; pick another key.

```lua
hl.bind(
 mainMod .. " + M",
 hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'")
)
```

### Dwindle split toggle (`conf/keymaps.lua`)

Dwindle layout only.

```lua
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
```

### Disabling binds and rules at runtime

`hl.bind` and `hl.window_rule` return handles that can be toggled, e.g. to turn
off `SUPER+Q` or the suppress-maximize rule in `conf/rules.lua`:

```lua
local closeWindowBind = bind(mainMod .. " + Q", hl.dsp.window.close(), { ... })
closeWindowBind:set_enabled(false)

local suppressMaximizeRule = hl.window_rule({ name = "suppress-maximize-events", ... })
suppressMaximizeRule:set_enabled(false)
```

### Layer rule (`conf/rules.lua`)

Layer rules also return a handle. See
<https://wiki.hypr.land/configuring/core/rules/>.

```lua
local overlayLayerRule = hl.layer_rule({
 name = "no-anim-overlay",
 match = { namespace = "^my-overlay$" },
 no_anim = true,
})
overlayLayerRule:set_enabled(false)
```

### Smart gaps / no gaps when only (`conf/rules.lua`)

See <https://wiki.hypr.land/configuring/core/rules/workspace-rules/>. Gaps are 0
globally right now, so this only matters if gaps come back.

```lua
hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
hl.workspace_rule({ workspace = "f[1]", gaps_out = 0, gaps_in = 0 })
hl.window_rule({
 name = "no-gaps-wtv1",
 match = { float = false, workspace = "w[tv1]" },
 border_size = 0,
 rounding = 0,
})
hl.window_rule({
 name = "no-gaps-f1",
 match = { float = false, workspace = "f[1]" },
 border_size = 0,
 rounding = 0,
})
```

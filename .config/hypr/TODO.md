# TODO

## Features

- `super + alt + shift + w` for a new hidden workspace, so making one does not
  have to go through the picker (`conf/workspaces/hidden.lua`)
- teamspeak should prefer right side and comms workspace
- wl freeze to pause games in background and free up gpu
- hyprmoncfg for different monitor setups/arragements that saves

## Disabled config snippets

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

### Dwindle split toggle (`conf/keymaps.lua`)

Dwindle layout only.

```lua
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
```

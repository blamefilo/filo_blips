# filo_blips

A FiveM blip manager resource for GTA V multiplayer servers. Allows players to create personal map blips and admins to create server-wide persistent blips — all through an in-game context menu.

## Features

- **Personal blips** — any player can create, edit, and delete their own blips, persisted locally via KVP across sessions
- **Global blips** — admins can create server-wide blips visible to all players, stored server-side and synced via statebags
- **Full editor** — name, sprite (1–921), scale, color, and coordinates (current position or waypoint) are all configurable at creation and after the fact
- **Category system** — scriptable blip categories with custom labels, exposed via exports for use by other resources
- **Blip API** — create, get, hide, and delete blips from other resources using exports
- **Version checker** — automatic update check on resource start

## Dependencies

| Dependency | Notes |
|---|---|
| [ox_lib](https://github.com/overextended/ox_lib) | Context menus, input dialogs, callbacks, string utils |
| [oxmysql](https://github.com/overextended/oxmysql) | Required by manifest |
| [community_bridge](https://github.com/The-Order-Of-The-Sacred-Framework/community_bridge) | Framework abstraction (admin check, notifications) |

## Installation

1. Download and place `filo_blips` into your server's `resources` folder.
2. Ensure all dependencies are installed and started before `filo_blips` in your `server.cfg`.
3. Add to `server.cfg`:
   ```
   ensure filo_blips
   ```

## Configuration

`shared/sh-config.lua`

```lua
Config.Command = 'cblip'  -- Command to open the blip menu
```

## Usage

| Action | How |
|---|---|
| Open menu | Run `/{command}` in chat (default: `/cblip`) |
| Create personal blip | Open menu → Create Blip → fill fields → Create Blip (with "Visible to all" off) |
| Create global blip | Admins only — toggle "Visible to all" on before creating |
| Edit a blip | Open menu → Manage Blips → select blip → edit fields → Save Changes |
| Delete a blip | Open menu → Manage Blips → select blip → Delete Blip |

## Exports (Client)

```lua
-- Create a blip
exports.filo_blips:createBlip({
    name     = 'my_blip',       -- unique identifier
    label    = 'My Location',   -- map label
    sprite   = 1,               -- blip sprite ID (1–921)
    scale    = 0.9,             -- blip scale (default: 0.9)
    color    = 1,               -- blip color integer
    coords   = vector3(x, y, z),
    category = 'mycategory',    -- optional, must be registered first
    display  = 4,               -- optional (default: 4)
    shortRange = true           -- optional (default: true)
})

-- Get a blip by name
local blip = exports.filo_blips:getBlip('my_blip')

-- Hide or show a blip
exports.filo_blips:hideBlip('my_blip', true)   -- hide
exports.filo_blips:hideBlip('my_blip', false)  -- show

-- Delete a blip
exports.filo_blips:deleteBlip('my_blip')

-- Hide / show all blips in a category
exports.filo_blips:hideBlipCategory('mycategory')
exports.filo_blips:showBlipCategory('mycategory')

-- Create a category
exports.filo_blips:createCategory({
    name  = 'mycategory',       -- internal identifier
    label = 'My Category',      -- displayed in the map legend
})

-- Get a category
local cat = exports.filo_blips:getCategory('mycategory')

-- Delete a category
exports.filo_blips:deleteCategory('mycategory')
```

## Blip Sprite Reference

Sprite IDs 1–921 — see the [FiveM blip reference](https://docs.fivem.net/docs/game-references/blips/) for a full list.

## Links

- Discord: https://discord.gg/bErPEKvRXg
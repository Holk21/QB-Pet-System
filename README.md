# qb-pets

A QBCore resource that adds a Pet Shop and controllable pets with a slick NUI panel.

## Features
- Pet Shop NPC with draggable panel UI
- Buy animals, food, water, and health items
- Persistent pets saved to database
- `/pet` command opens Pet Control panel (same style as shop)
- Spawn, despawn, feed, play, sit, carry, put in car
- UI can be dragged around the screen, position saved
- Close with ❌ (mouse releases cleanly)

## Requirements
- [qb-core](https://github.com/qbcore-framework/qb-core)
- [qb-target](https://github.com/qbcore-framework/qb-target)
- [qb-menu](https://github.com/qbcore-framework/qb-menu)
- [qb-inventory](https://github.com/qbcore-framework/qb-inventory)
- [oxmysql](https://github.com/overextended/oxmysql)
- [okokNotify](https://okok.tebex.io/) (optional, configurable in `config.lua`)

## Installation
1. Drop `qb-pets` into your `resources/[custom]` folder.
2. Import the SQL from `sql/pets.sql` into your database.
3. Add to your `server.cfg` after core dependencies:
   ```
   ensure qb-pets
   ```
4. Add item definitions in `qb-core/shared/items.lua`:
   ```lua
   ['pet_food']  = { name = 'pet_food',  label = 'Pet Food',  weight = 100, type = 'item', image = 'pet_food.png',  unique = false, useable = false, shouldClose = true, description = 'Tasty chow' },
   ['pet_treat'] = { name = 'pet_treat', label = 'Pet Treat', weight = 50,  type = 'item', image = 'pet_treat.png', unique = false, useable = false, shouldClose = true, description = 'Small reward' },
   ['pet_water'] = { name = 'pet_water', label = 'Pet Water', weight = 100, type = 'item', image = 'pet_water.png', unique = false, useable = false, shouldClose = true, description = 'Fresh water' },
   ['pet_med']   = { name = 'pet_med',   label = 'Pet Medkit',weight = 250, type = 'item', image = 'pet_med.png',   unique = false, useable = false, shouldClose = true, description = 'Pet health care' },
   ```
5. Copy the provided PNGs from `qb-pets/item_images/` into your `qb-inventory/html/images/` folder.

## Usage
- Approach the NPC and use qb-target → **Open Pet Shop**.
- Buy pets or items (uses bank balance).
- Use `/pet` to open the Pet Control panel and manage your pets.
- Drag the panel around; close with ❌.

## Commands
- `/pet` → open Pet Control panel
- `/uiblurreset` → emergency fallback to clear mouse focus if ever stuck

## Configuration
See `config.lua` to adjust:
- Shop location & ped model
- Animal breeds & prices
- Item prices and effects
- Hunger/thirst/health decay rates

## Notes
- Pets persist per character (citizenid).
- Make sure the models listed in `config.lua` exist in your game build (e.g., `a_c_husky`).


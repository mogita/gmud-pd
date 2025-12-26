---
type: "always_apply"
---

# Project Scope

- `gmud-pd` is our game project for Play.date, you can only modify this project.
- `gmud` with c and assembly code is the original game that we use only as a reference for game play, quest, dialogs, etc. You must NEVER edit this project.

---

# Adding Interactive POIs

To add a new interactive POI:

1. **Define POI in map data** (`source/data/poi/map*.lua`):
   ```lua
   {
     id = "unique_id",
     category = "interactive|npc|passage",
     handlerName = "handler_name",
     x = 100, width = 20,
     data = { --[[ handler-specific data ]] }
   }
   ```

2. **Add handler** in `source/poi/handlers/`:
   - `interactive.lua` - objects (wells, beds, items)
   - `npc.lua` - NPCs with menus
   - `passage.lua` - doors, paths, exits

3. **Register handler** inside the setup function:
   ```lua
   registry:register("handler_name", function(player, poi, context)
       -- Use context.showMessage(text) for visual feedback
       context.showMessage("消息文本")
   end)
   ```

4. **Reference original gmud** for authentic messages - search `talk.s`, `string*.s` for Chinese text.

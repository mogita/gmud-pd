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
   - `interactive.lua` - objects (wells, beds, items) - **requires player facing UP**
   - `npc.lua` - NPCs with menus - **requires player facing UP**
   - `passage.lua` - doors, paths, exits - **no facing requirement**

3. **Register handler** inside the setup function:
   ```lua
   registry:register("handler_name", function(player, poi, context)
       -- Use context.showMessage(text) for visual feedback
       context.showMessage("消息文本")
   end)
   ```

4. **Reference original gmud** for authentic messages - search `talk.s`, `string*.s` for Chinese text.

## POI Interaction Rules

- **Interactive POIs** (wells, items): Press **A** when facing UP
- **NPCs**: Press **A** when facing UP
- **Passages**: Press **UP** to enter buildings/maps, **DOWN** to exit (no facing requirement)

---

# Dialog/Message Display Guidelines

- Show A button icon
- Only A advances to next page
- On last page (including one page only): no A button icon, dismissible with A, B, Left, or Right (Left/Right starts walking immediately)

-- POI definitions for map22
--
-- Categories (required):
--   "interactive" - Objects (well, sign, board) - trigger: A
--   "passage"     - Transitions (door, path)    - trigger: up/down
--   "npc"         - Characters with menus       - trigger: A
--
-- Fields:
--   id: string          - Unique identifier (required)
--   category: string    - POI category (required)
--   x, width: number    - Trigger area in world coordinates (required)
--   trigger: string     - "A", "up", or "down" (optional, uses category default)
--   handlerName: string - Named handler (optional)
--   data: table         - Category-specific data (optional)
--
-- Passage data fields:
--   destination: string - Target map ID (e.g., "map1")
--   exitPosition: "left"|"right"|"center"|number - Player X on destination
--   exitFacing: "left"|"right"|"up"|"down" - Player facing after transition

return {
	-- Exit to map1
	{
		id = "passage_to_1",
		category = "passage",
		x = 0,
		width = 30,
		data = {
			destination = "map1",
			exitPosition = 295, -- Mid position of passage_to_22 (280 + 30/2)
			exitFacing = "down", -- Face down (toward camera) after transition
		},
	},
}

-- POI definitions for map1
--
-- Categories (required):
--   "interactive" - Objects (well, sign, board) - trigger: A
--   "passage"     - Transitions (door, path)    - trigger: up
--   "npc"         - Characters with menus       - trigger: A
--
-- Fields:
--   id: string          - Unique identifier (required)
--   category: string    - POI category (required)
--   x, width: number    - Trigger area in world coordinates (required)
--   trigger: string     - "A", "up", or "down" (optional, uses category default)
--   handlerName: string - Named handler (optional)
--   data: table         - Category-specific data (optional)

return {
	-- Well
	{
		id = "well_1",
		category = "interactive",
		x = 116,
		width = 25,
		handlerName = "drink_water",
	},
}

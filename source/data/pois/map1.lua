-- POI definitions for map1
-- Each POI entry defines an interactive area on the map
--
-- Required fields:
--   id: string       - Unique identifier
--   type: string     - Category (e.g., "well", "door", "npc")
--   x: number        - World X position (left edge of trigger area)
--   width: number    - Width of trigger area in pixels
--   action: string   - "up" or "down" button to trigger
--
-- Trigger (one required):
--   onTrigger: function(player, poi, poiManager) - Inline callback
--   actionName: string - Named handler registered in main.lua
--
-- Optional:
--   data: table - Custom metadata for the handler

return {
	-- Example: A well with inline trigger
	{
		id = "well_1",
		type = "well",
		x = 116,
		width = 25,
		action = "up",
		onTrigger = function(player, poi, poiManager)
			print("Player interacted with the well!")
		end,
		data = {
			description = "An old stone well",
		},
	},
}

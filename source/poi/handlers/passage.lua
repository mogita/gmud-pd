-- Passage POI Handlers
-- Handles transitions between maps (unified format for all passages)
--
-- POI data fields (unified):
--   destination: string - Target map ID (e.g., "map22")
--   exitPosition: "left"|"right"|"center"|number - Player X position on destination map
--   exitFacing: "left"|"right"|"up"|"down" - Player facing direction after transition

-- Helper function to perform map transition
local function doTransition(poi, context)
	local data = poi.data or {}
	local destination = data.destination

	if not destination then
		print("[Passage] No destination specified for: " .. poi.id)
		return false
	end

	if context.transitionToMap then
		local options = {
			exitPosition = data.exitPosition,
			exitFacing = data.exitFacing,
		}
		context.transitionToMap(destination, options)
		return true
	else
		print("[Passage] transitionToMap not available in context")
		return false
	end
end

-- Setup function called by init.lua with the registry
return function(registry)
	-- Default handler for passage category
	-- All passages use the same unified data format
	registry:registerCategoryDefault("passage", function(player, poi, context)
		print("[Passage] Transitioning via: " .. poi.id)
		doTransition(poi, context)
	end)
end

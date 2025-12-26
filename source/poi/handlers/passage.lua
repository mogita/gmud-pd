-- Passage POI Handlers
-- Handles doors, paths, and transitions between maps/rooms

local handlers = import("poi/handlers/init")
local registry = handlers.registry

-- Handler: Enter a door/building
registry:register("enter_door", function(player, poi, context)
	print("[Passage] Entering door: " .. poi.id)

	local destination = poi.data.destination
	local exitX = poi.data.exitX or 50

	if not destination then
		print("[Passage] No destination specified for door: " .. poi.id)
		return
	end

	-- TODO: Implement map transition
	-- context.gameController:transitionToMap(destination, exitX)

	print("[Passage] Would transition to: " .. destination .. " at x=" .. exitX)
end)

-- Handler: Travel via path to another map
registry:register("travel_path", function(player, poi, context)
	print("[Passage] Taking path: " .. poi.id)

	local destination = poi.data.destination
	local exitX = poi.data.exitX or 50

	if not destination then
		print("[Passage] No destination specified for path: " .. poi.id)
		return
	end

	-- TODO: Implement map transition with optional travel animation
	-- context.gameController:transitionToMap(destination, exitX, {animation = "walk"})

	print("[Passage] Would travel to: " .. destination .. " at x=" .. exitX)
end)

-- Handler: Exit a room/building (returns to previous map)
registry:register("exit_room", function(player, poi, context)
	print("[Passage] Exiting via: " .. poi.id)

	local returnTo = poi.data.returnTo
	local returnX = poi.data.returnX or 100

	-- TODO: Implement return transition
	-- context.gameController:returnToPreviousMap(returnX)

	print("[Passage] Would return to: " .. (returnTo or "previous map") .. " at x=" .. returnX)
end)

-- Default handler for passage category (fallback when no handlerName specified)
registry:registerCategoryDefault("passage", function(player, poi, context)
	print("[Passage] No handler for POI: " .. poi.id)
end)

return {}

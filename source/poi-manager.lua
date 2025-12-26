-- POI Manager
-- Manages POIs for the current map, handles collision detection and trigger events

local gfx <const> = playdate.graphics
local POI = import("poi")
local handlers = import("poi/handlers/init")

---@class POIManager
---@field pois POI[] List of POIs for current map
---@field handlerRegistry HandlerRegistry Handler registry for POI actions
---@field currentPOI POI|nil The POI the player is currently in (for enter/exit hooks)
---@field mapId string|nil Current map identifier
---@field context table Shared context for handlers
---@field debugMode boolean Whether to draw debug visualization
---@field debugLineHeight number Height of debug lines in pixels
---@field debugMapBottomY number Y position of map bottom for debug drawing
local POIManager = {}
POIManager.__index = POIManager

---Create a new POI Manager
---@return POIManager
function POIManager.new()
	local self = setmetatable({}, POIManager)

	self.pois = {}
	self.handlerRegistry = handlers.registry
	self.currentPOI = nil
	self.mapId = nil
	self.context = {} -- Will be populated with game systems (dialog, shop, etc.)
	self.debugMode = false
	self.debugLineHeight = 3
	self.debugMapBottomY = 108

	return self
end

---Set context for handlers (game systems like dialog, shop, combat)
---@param context table Table of game systems
function POIManager:setContext(context)
	self.context = context
end

---Enable or disable debug visualization
---@param enabled boolean
function POIManager:setDebugMode(enabled)
	self.debugMode = enabled
end

---Set parameters for debug drawing
---@param mapBottomY number The Y position of the map bottom
---@param lineHeight number|nil Height of debug lines (default 3)
function POIManager:setDebugDrawParams(mapBottomY, lineHeight)
	self.debugMapBottomY = mapBottomY
	self.debugLineHeight = lineHeight or 3
end

---Draw debug visualization of POI positions
---Call this after drawing the map, passing the camera for coordinate conversion
---@param camera table Camera object with getOffset() method
function POIManager:drawDebug(camera)
	if not self.debugMode or #self.pois == 0 then
		return
	end

	local cameraOffset = camera:getOffset()
	local lineY = self.debugMapBottomY - self.debugLineHeight

	-- Draw black lines at POI positions
	gfx.setColor(gfx.kColorBlack)

	for _, poi in ipairs(self.pois) do
		-- Convert world X to screen X
		local screenX = poi.x - cameraOffset
		local screenWidth = poi.width

		-- Only draw if visible on screen
		if screenX + screenWidth > 0 and screenX < 400 then
			gfx.fillRect(screenX, lineY, screenWidth, self.debugLineHeight)
		end
	end
end

---Register a named action handler
---@param name string The handler name
---@param handler function The handler function(player, poi, context)
function POIManager:registerHandler(name, handler)
	self.handlerRegistry:register(name, handler)
end

---Load POIs for a specific map
---@param mapId string The map identifier (e.g., "map1")
---@return boolean success Whether POIs were loaded successfully
function POIManager:loadForMap(mapId)
	self.pois = {}
	self.currentPOI = nil
	self.mapId = mapId

	-- Load POI data file using playdate.file.run() for dynamic loading
	local dataPath = "data/pois/" .. mapId .. ".pdz"

	if not playdate.file.exists(dataPath) then
		return false
	end

	local poiData, err = playdate.file.run(dataPath)
	if err or not poiData then
		return false
	end

	-- Create POI objects from data
	for _, config in ipairs(poiData) do
		local poi = POI.new(config)
		table.insert(self.pois, poi)
	end

	return true
end

---Find which POI the player is currently in (if any)
---@param playerX number Player's world X position
---@param playerWidth number|nil Player's width for collision (default 0)
---@return POI|nil The POI the player is in, or nil
function POIManager:findPOIAtPosition(playerX, playerWidth)
	for _, poi in ipairs(self.pois) do
		if poi:containsX(playerX, playerWidth) then
			return poi
		end
	end
	return nil
end

---Update POI state based on player position (call every frame)
---Handles enter/exit hooks
---@param playerX number Player's world X position
---@param playerWidth number|nil Player's width for collision
function POIManager:updatePlayerPosition(playerX, playerWidth)
	local newPOI = self:findPOIAtPosition(playerX, playerWidth)

	-- Check for POI change
	if newPOI ~= self.currentPOI then
		-- Exit previous POI
		if self.currentPOI then
			self:onPlayerExitPOI(self.currentPOI)
		end

		-- Enter new POI
		if newPOI then
			self:onPlayerEnterPOI(newPOI)
		end

		self.currentPOI = newPOI
	end
end

---Execute the trigger for a specific POI
---@param player table The player object
---@param poi POI The POI to trigger
---@return boolean success Whether the trigger was executed
function POIManager:triggerPOI(player, poi)
	-- Use handler registry to execute the appropriate handler
	local handled = self.handlerRegistry:handle(player, poi, self.context)

	if not handled then
		print("Warning: POI '" .. poi.id .. "' has no handler")
	end

	return handled
end

---Try to trigger a POI interaction
---@param player table The player object
---@param triggerKey string The trigger key: "A", "up", or "down"
---@return boolean triggered Whether a POI was triggered
function POIManager:tryTrigger(player, triggerKey)
	if not self.currentPOI then
		return false
	end

	-- Check if the POI responds to this trigger
	if not self.currentPOI:respondsToTrigger(triggerKey) then
		return false
	end

	-- Trigger the POI
	return self:triggerPOI(player, self.currentPOI)
end

---Hook: Called when player enters a POI zone
---Override this method for visual feedback (e.g., show interaction prompt)
---@param poi POI The POI being entered
function POIManager:onPlayerEnterPOI(poi)
	-- Empty by default - override for visual feedback
end

---Hook: Called when player exits a POI zone
---Override this method for visual feedback (e.g., hide interaction prompt)
---@param poi POI The POI being exited
function POIManager:onPlayerExitPOI(poi)
	-- Empty by default - override for visual feedback
end

---Get all POIs of a specific type
---@param poiType string The type to filter by
---@return POI[]
function POIManager:getPOIsByType(poiType)
	local result = {}
	for _, poi in ipairs(self.pois) do
		if poi.type == poiType then
			table.insert(result, poi)
		end
	end
	return result
end

---Get a POI by its ID
---@param id string The POI ID
---@return POI|nil
function POIManager:getPOIById(id)
	for _, poi in ipairs(self.pois) do
		if poi.id == id then
			return poi
		end
	end
	return nil
end

return POIManager

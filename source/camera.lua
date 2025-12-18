-- Camera system for horizontal scrolling
-- Handles viewport offset and scrolling logic

---@class Camera
---@field offsetX number Current horizontal offset of the camera (world scroll position)
---@field scrollTriggerLeft number Left edge trigger zone (screen coordinates)
---@field scrollTriggerRight number Right edge trigger zone (screen coordinates)
---@field mapWidth number Total width of the current map
---@field viewportWidth number Width of the viewport (screen width)
local Camera = {}
Camera.__index = Camera

---Create a new camera
---@param config {mapWidth: number, scrollTriggerOffset: number?}
---@return Camera
function Camera.new(config)
	local self = setmetatable({}, Camera)
	
	self.offsetX = 0
	self.mapWidth = config.mapWidth or 800
	self.viewportWidth = 400  -- Playdate screen width
	
	-- Scroll trigger zones (default 100px from edges)
	local triggerOffset = config.scrollTriggerOffset or 100
	self.scrollTriggerLeft = triggerOffset
	self.scrollTriggerRight = self.viewportWidth - triggerOffset
	
	return self
end

---Update camera position based on player position
---@param playerWorldX number Player's position in world coordinates
---@return number newOffsetX The new camera offset
function Camera:update(playerWorldX)
	-- Convert player world position to screen position
	local playerScreenX = playerWorldX - self.offsetX
	
	-- Check if player is in the right scroll trigger zone
	if playerScreenX > self.scrollTriggerRight then
		-- Try to scroll right
		local desiredOffset = playerWorldX - self.scrollTriggerRight
		local maxOffset = self.mapWidth - self.viewportWidth
		self.offsetX = math.min(desiredOffset, maxOffset)
	
	-- Check if player is in the left scroll trigger zone
	elseif playerScreenX < self.scrollTriggerLeft then
		-- Try to scroll left
		local desiredOffset = playerWorldX - self.scrollTriggerLeft
		self.offsetX = math.max(desiredOffset, 0)
	end
	
	return self.offsetX
end

---Get the current camera offset
---@return number offsetX
function Camera:getOffset()
	return self.offsetX
end

---Convert world coordinates to screen coordinates
---@param worldX number
---@return number screenX
function Camera:worldToScreen(worldX)
	return worldX - self.offsetX
end

---Convert screen coordinates to world coordinates
---@param screenX number
---@return number worldX
function Camera:screenToWorld(screenX)
	return screenX + self.offsetX
end

---Check if camera is at the left boundary
---@return boolean
function Camera:isAtLeftBoundary()
	return self.offsetX <= 0
end

---Check if camera is at the right boundary
---@return boolean
function Camera:isAtRightBoundary()
	return self.offsetX >= self.mapWidth - self.viewportWidth
end

return Camera


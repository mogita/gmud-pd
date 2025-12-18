-- Map/World system
-- Handles map rendering with repeating pattern background

import "CoreLibs/graphics"

local gfx <const> = playdate.graphics

---@class Map
---@field width number Total width of the map in pixels
---@field height number Height of the map area (upper half = 120px)
---@field camera Camera Reference to the camera
---@field patternImage playdate.graphics.image Repeating pattern for background
local Map = {}
Map.__index = Map

---Create a new map
---@param config {width: number, camera: Camera}
---@return Map
function Map.new(config)
	local self = setmetatable({}, Map)
	
	self.width = config.width or 800
	self.height = 120  -- Upper half of screen
	self.camera = config.camera
	
	-- Create a simple repeating pattern (8x8 checkerboard)
	self.patternImage = self:createPattern()
	
	return self
end

---Create a simple repeating pattern for the background
---@return playdate.graphics.image
function Map:createPattern()
	local patternSize = 16
	local pattern = gfx.image.new(patternSize, patternSize)
	
	gfx.pushContext(pattern)
		-- Draw a simple grid pattern
		gfx.setColor(gfx.kColorWhite)
		gfx.fillRect(0, 0, patternSize, patternSize)
		
		gfx.setColor(gfx.kColorBlack)
		-- Draw grid lines
		gfx.drawLine(0, 0, patternSize, 0)  -- Top
		gfx.drawLine(0, 0, 0, patternSize)  -- Left
		
		-- Draw a small dot in the center
		gfx.fillRect(patternSize/2 - 1, patternSize/2 - 1, 2, 2)
	gfx.popContext()
	
	return pattern
end

---Draw the map background
function Map:draw()
	local offsetX = self.camera:getOffset()
	
	-- Calculate which pattern tiles to draw
	local patternWidth = self.patternImage:getSize()
	local startTile = math.floor(offsetX / patternWidth)
	local endTile = math.ceil((offsetX + 400) / patternWidth)
	
	-- Draw repeating pattern
	for i = startTile, endTile do
		local worldX = i * patternWidth
		local screenX = self.camera:worldToScreen(worldX)
		
		-- Only draw if visible on screen
		if screenX < 400 and screenX + patternWidth > 0 then
			self.patternImage:draw(screenX, 0)
		end
	end
	
	-- Draw map boundaries (visual indicators)
	local leftBoundaryScreenX = self.camera:worldToScreen(0)
	local rightBoundaryScreenX = self.camera:worldToScreen(self.width)
	
	gfx.setColor(gfx.kColorBlack)
	
	-- Left boundary
	if leftBoundaryScreenX >= 0 and leftBoundaryScreenX < 400 then
		gfx.setLineWidth(3)
		gfx.drawLine(leftBoundaryScreenX, 0, leftBoundaryScreenX, self.height)
	end
	
	-- Right boundary
	if rightBoundaryScreenX >= 0 and rightBoundaryScreenX < 400 then
		gfx.setLineWidth(3)
		gfx.drawLine(rightBoundaryScreenX, 0, rightBoundaryScreenX, self.height)
	end
	
	gfx.setLineWidth(1)  -- Reset line width
end

---Get the map width
---@return number
function Map:getWidth()
	return self.width
end

---Set the map width
---@param width number
function Map:setWidth(width)
	self.width = width
end

return Map


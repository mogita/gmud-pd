-- Player character controller
-- Handles player movement and input

import("CoreLibs/graphics")
import("CoreLibs/sprites")

local gfx <const> = playdate.graphics

-- Import Camera for type checking (Lua LS will now understand the types)
local _ = import("camera")

---@class Player : playdate.graphics.sprite
---@field worldX number Player's position in world coordinates
---@field worldY number Player's position in world coordinates (fixed for now)
---@field moveSpeed number Movement speed in pixels per frame
---@field mapWidth number Width of the current map (for boundary checking)
---@field camera Camera Reference to the camera
---@field canMove boolean Whether the player can move (disabled during dialogs)
---@field halfWidth number Half of the sprite's width (for boundary checking)
local Player = {}
Player.__index = Player
setmetatable(Player, { __index = gfx.sprite })

---Create a new player
---@param config {imagePath: string, startX: number?, startY: number?, moveSpeed: number?, mapWidth: number, camera: Camera}
---@return Player
function Player.new(config)
	---@type Player
	---@diagnostic disable-next-line: assign-type-mismatch
	local self = gfx.sprite.new()
	setmetatable(self, Player)

	-- Load player image
	local image = gfx.image.new(config.imagePath)
	if not image then
		error("Failed to load player image: " .. config.imagePath)
	end

	self:setImage(image)

	-- Set anchor to bottom-center (0.5, 1.0)
	-- This means the sprite's bottom-center point is at worldY
	self:setCenter(0.5, 1.0)

	-- Store sprite dimensions for boundary checking
	-- Since anchor is at center (0.5), we need half-width for boundaries
	local width, _ = image:getSize()
	self.halfWidth = width / 2

	-- World position (absolute coordinates in the map)
	self.worldX = config.startX or 50
	self.worldY = config.startY or 224 -- Center Y of player area (bottom at 240)

	-- Movement settings
	self.moveSpeed = config.moveSpeed or 3
	self.mapWidth = config.mapWidth
	self.camera = config.camera
	self.canMove = true -- Player can move by default

	-- Set initial screen position
	self:updateScreenPosition()

	-- Set z-index to be above background
	self:setZIndex(100)

	return self
end

---Update screen position based on world position and camera offset
function Player:updateScreenPosition()
	local screenX = self.camera:worldToScreen(self.worldX)
	self:moveTo(screenX, self.worldY)
end

---Handle player input and movement
function Player:update()
	-- Don't process movement if player is disabled (e.g., during dialog)
	if not self.canMove then
		return
	end

	local moved = false

	-- Handle left/right movement
	if playdate.buttonIsPressed(playdate.kButtonLeft) then
		self.worldX -= self.moveSpeed
		moved = true
	elseif playdate.buttonIsPressed(playdate.kButtonRight) then
		self.worldX += self.moveSpeed
		moved = true
	end

	-- Clamp player position to map boundaries
	-- Since anchor is at center (0.5), worldX represents the sprite's center
	-- Left edge: worldX - halfWidth should be >= 0
	-- Right edge: worldX + halfWidth should be <= mapWidth
	local minX = self.halfWidth
	local maxX = self.mapWidth - self.halfWidth

	if self.worldX < minX then
		self.worldX = minX
	elseif self.worldX > maxX then
		self.worldX = maxX
	end

	-- Update camera based on player position
	if moved then
		self.camera:update(self.worldX)
		self:updateScreenPosition()
	end
end

---Get player's world position
---@return number worldX, number worldY
function Player:getWorldPosition()
	return self.worldX, self.worldY
end

---Set the map width (for boundary checking)
---@param width number
function Player:setMapWidth(width)
	self.mapWidth = width
end

---Enable or disable player movement
---@param enabled boolean
function Player:setCanMove(enabled)
	self.canMove = enabled
end

return Player

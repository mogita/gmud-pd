-- Player character controller
-- Handles player movement and input with spritesheet animation

import("CoreLibs/graphics")
import("CoreLibs/sprites")

local gfx <const> = playdate.graphics

-- Import Camera for type checking (Lua LS will now understand the types)
local _ = import("camera")

-- Animation frame indices (1-based, matching spritesheet order)
-- Spritesheet: 4 frames of 32x32, arranged horizontally
local FRAME_FRONT <const> = 1 -- Standing facing front (toward camera)
local FRAME_BACK <const> = 2 -- Standing facing back (away from camera)
local FRAME_STAND_RIGHT <const> = 3 -- Standing facing right
local FRAME_WALK_RIGHT <const> = 4 -- Walking facing right

-- Direction constants
local DIR_LEFT <const> = 1
local DIR_RIGHT <const> = 2

---@class Player : playdate.graphics.sprite
---@field worldX number Player's position in world coordinates
---@field worldY number Player's position in world coordinates (fixed for now)
---@field moveSpeed number Movement speed in pixels per frame
---@field mapWidth number Width of the current map (for boundary checking)
---@field camera Camera Reference to the camera
---@field canMove boolean Whether the player can move (disabled during dialogs)
---@field halfWidth number Half of the sprite's width (for boundary checking)
---@field images any Image table containing animation frames
---@field currentFrame number Current animation frame index (persists on release)
---@field facing number Current facing direction (DIR_LEFT or DIR_RIGHT)
---@field animFrameCounter number Counter for animation frame timing
---@field animSpeedRatio number How many update frames to wait before toggling animation (higher = slower)
---@field wasMovingLeft boolean Whether left was pressed in the previous frame
---@field wasMovingRight boolean Whether right was pressed in the previous frame
local Player = {}
Player.__index = Player
setmetatable(Player, { __index = gfx.sprite })

---Create a new player
---@param config {imagePath: string, startX: number?, startY: number?, moveSpeed: number?, mapWidth: number, camera: Camera, animSpeedRatio: number?}
---@return Player
function Player.new(config)
	---@type Player
	---@diagnostic disable-next-line: assign-type-mismatch
	local self = gfx.sprite.new()
	setmetatable(self, Player)

	-- Load player spritesheet as imagetable
	-- The imagetable expects files named like "image-table-32-32.png" or
	-- individual files, but we can also load a single image and split it
	self.images = gfx.imagetable.new(config.imagePath)
	if not self.images then
		error("Failed to load player spritesheet: " .. config.imagePath)
	end

	-- Animation state
	self.currentFrame = FRAME_STAND_RIGHT
	self.facing = DIR_RIGHT
	self.animFrameCounter = 0
	-- Animation speed: higher = slower animation
	-- 1 = toggle every frame, 3 = toggle every 3 frames, etc.
	self.animSpeedRatio = config.animSpeedRatio or 3
	self.wasMovingLeft = false
	self.wasMovingRight = false

	-- Set initial image (standing facing right)
	self:setImage(self.images:getImage(self.currentFrame))

	-- Set anchor to bottom-center (0.5, 1.0)
	-- This means the sprite's bottom-center point is at worldY
	self:setCenter(0.5, 1.0)

	-- Store sprite dimensions for boundary checking
	-- Since anchor is at center (0.5), we need half-width for boundaries
	local width, _ = self.images:getImage(1):getSize()
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

---Update the sprite image based on current animation state
function Player:updateImage()
	local image = self.images:getImage(self.currentFrame)

	if self.facing == DIR_LEFT then
		-- Flip horizontally when facing left
		self:setImage(image, gfx.kImageFlippedX)
	else
		self:setImage(image)
	end
end

---Toggle walk animation frame between standing and walking (with throttling)
---@param justPressed boolean Whether the key was just pressed (toggle immediately)
---@return boolean true if frame was toggled, false if still counting
function Player:toggleWalkFrame(justPressed)
	-- If key was just pressed, toggle immediately
	if justPressed then
		self.animFrameCounter = 0
		if self.currentFrame == FRAME_STAND_RIGHT then
			self.currentFrame = FRAME_WALK_RIGHT
		elseif self.currentFrame == FRAME_WALK_RIGHT then
			self.currentFrame = FRAME_STAND_RIGHT
		else
			-- Was facing front/back, start with walk frame
			self.currentFrame = FRAME_WALK_RIGHT
		end
		return true
	end

	-- Otherwise, use throttled toggling
	self.animFrameCounter += 1

	-- Only toggle when counter reaches the ratio threshold
	if self.animFrameCounter >= self.animSpeedRatio then
		self.animFrameCounter = 0

		if self.currentFrame == FRAME_STAND_RIGHT then
			self.currentFrame = FRAME_WALK_RIGHT
		elseif self.currentFrame == FRAME_WALK_RIGHT then
			self.currentFrame = FRAME_STAND_RIGHT
		else
			-- Was facing front/back, start with walk frame
			self.currentFrame = FRAME_WALK_RIGHT
		end
		return true
	end

	return false
end

---Handle player input and movement
function Player:update()
	-- Don't process movement if player is disabled (e.g., during dialog)
	if not self.canMove then
		return
	end

	local moved = false
	local movingLeft = playdate.buttonIsPressed(playdate.kButtonLeft)
	local movingRight = playdate.buttonIsPressed(playdate.kButtonRight)
	local pressedUp = playdate.buttonIsPressed(playdate.kButtonUp)
	local pressedDown = playdate.buttonIsPressed(playdate.kButtonDown)

	-- Handle input - currentFrame persists when no button is pressed
	if pressedUp then
		-- Face back (away from camera)
		self.currentFrame = FRAME_BACK
		self.animFrameCounter = 0 -- Reset counter when changing direction
		self.wasMovingLeft = false
		self.wasMovingRight = false
	elseif pressedDown then
		-- Face front (toward camera)
		self.currentFrame = FRAME_FRONT
		self.animFrameCounter = 0 -- Reset counter when changing direction
		self.wasMovingLeft = false
		self.wasMovingRight = false
	elseif movingLeft then
		-- Move left with walk animation
		self.worldX -= self.moveSpeed
		self.facing = DIR_LEFT
		moved = true

		-- Check if this is a new press (toggle immediately) or continued hold (throttled)
		local justPressed = not self.wasMovingLeft
		self:toggleWalkFrame(justPressed)
		self.wasMovingLeft = true
		self.wasMovingRight = false
	elseif movingRight then
		-- Move right with walk animation
		self.worldX += self.moveSpeed
		self.facing = DIR_RIGHT
		moved = true

		-- Check if this is a new press (toggle immediately) or continued hold (throttled)
		local justPressed = not self.wasMovingRight
		self:toggleWalkFrame(justPressed)
		self.wasMovingRight = true
		self.wasMovingLeft = false
	else
		-- No button pressed - keep currentFrame as-is (persists last frame)
		-- Reset counter so next movement starts fresh
		self.animFrameCounter = 0
		self.wasMovingLeft = false
		self.wasMovingRight = false
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

	-- Always update the sprite image
	self:updateImage()
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

---Check if player is facing up (away from camera)
---@return boolean
function Player:isFacingUp()
	return self.currentFrame == FRAME_BACK
end

return Player

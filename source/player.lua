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
---@field ignoreUpUntilRelease boolean Ignore UP key until released (after map transition)
---@field ignoreDownUntilRelease boolean Ignore DOWN key until released (after map transition)
---@field autoWalkDirection number? Auto-walk direction (DIR_LEFT or DIR_RIGHT), nil if not auto-walking
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
	self.ignoreUpUntilRelease = false -- Ignore UP key until released (used after map transition)
	self.ignoreDownUntilRelease = false -- Ignore DOWN key until released (used after map transition)
	self.autoWalkDirection = nil -- Auto-walk direction (DIR_LEFT or DIR_RIGHT), nil if not auto-walking

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
	local pressedB = playdate.buttonIsPressed(playdate.kButtonB)

	-- Clear ignore flags when buttons are released
	if not pressedUp then
		self.ignoreUpUntilRelease = false
	end
	if not pressedDown then
		self.ignoreDownUntilRelease = false
	end

	-- Calculate map boundaries
	local minX = self.halfWidth
	local maxX = self.mapWidth - self.halfWidth

	-- Handle input priority: Up/Down > Left/Right
	if pressedUp and not self.ignoreUpUntilRelease then
		-- Stop auto-walk if active
		self.autoWalkDirection = nil
		-- Face back (away from camera)
		self.currentFrame = FRAME_BACK
		self.animFrameCounter = 0
		self.wasMovingLeft = false
		self.wasMovingRight = false
	elseif pressedDown and not self.ignoreDownUntilRelease then
		-- Stop auto-walk if active
		self.autoWalkDirection = nil
		-- Face front (toward camera)
		self.currentFrame = FRAME_FRONT
		self.animFrameCounter = 0
		self.wasMovingLeft = false
		self.wasMovingRight = false
	elseif movingLeft then
		-- Left is pressed
		if pressedB and not self.wasMovingLeft then
			-- B + Left (first press): start auto-walk
			self.autoWalkDirection = DIR_LEFT
			self.facing = DIR_LEFT
			-- Start with walk frame for immediate animation
			self.currentFrame = FRAME_WALK_RIGHT
			self.animFrameCounter = 0
		elseif not pressedB then
			-- Left without B: stop auto-walk, do manual movement
			self.autoWalkDirection = nil
			self.worldX -= self.moveSpeed
			self.facing = DIR_LEFT
			moved = true

			local justPressed = not self.wasMovingLeft
			self:toggleWalkFrame(justPressed)
		end
		-- else: B + Left held (auto-walk already active), handled in auto-walk section below
		self.wasMovingLeft = true
		self.wasMovingRight = false
	elseif movingRight then
		-- Right is pressed
		if pressedB and not self.wasMovingRight then
			-- B + Right (first press): start auto-walk
			self.autoWalkDirection = DIR_RIGHT
			self.facing = DIR_RIGHT
			-- Start with walk frame for immediate animation
			self.currentFrame = FRAME_WALK_RIGHT
			self.animFrameCounter = 0
		elseif not pressedB then
			-- Right without B: stop auto-walk, do manual movement
			self.autoWalkDirection = nil
			self.worldX += self.moveSpeed
			self.facing = DIR_RIGHT
			moved = true

			local justPressed = not self.wasMovingRight
			self:toggleWalkFrame(justPressed)
		end
		-- else: B + Right held (auto-walk already active), handled in auto-walk section below
		self.wasMovingRight = true
		self.wasMovingLeft = false
	else
		-- No directional button pressed
		self.wasMovingLeft = false
		self.wasMovingRight = false
		-- Only reset counter if not auto-walking
		if not self.autoWalkDirection then
			self.animFrameCounter = 0
		end
	end

	-- Execute auto-walk if active
	if self.autoWalkDirection then
		if self.autoWalkDirection == DIR_LEFT then
			self.worldX -= self.moveSpeed
		else -- DIR_RIGHT
			self.worldX += self.moveSpeed
		end
		moved = true

		-- Animate walk (throttled)
		self:toggleWalkFrame(false)

		-- Check if reached edge - stop and show standing pose
		if self.worldX <= minX or self.worldX >= maxX then
			self.autoWalkDirection = nil
			self.currentFrame = FRAME_STAND_RIGHT
			self.animFrameCounter = 0
		end
	end

	-- Clamp player position to map boundaries
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

---Set player facing direction by name
---@param direction string "left", "right", "up", or "down"
function Player:setFacing(direction)
	if direction == "left" then
		self.facing = DIR_LEFT
		self.currentFrame = FRAME_STAND_RIGHT -- Use right frame, will be flipped
	elseif direction == "right" then
		self.facing = DIR_RIGHT
		self.currentFrame = FRAME_STAND_RIGHT
	elseif direction == "up" then
		self.facing = DIR_RIGHT -- Reset to unflipped state for front/back frames
		self.currentFrame = FRAME_BACK
	elseif direction == "down" then
		self.facing = DIR_RIGHT -- Reset to unflipped state for front/back frames
		self.currentFrame = FRAME_FRONT
	end
	self.animFrameCounter = 0
	-- Ignore UP/DOWN keys until released (prevents held button from overriding facing)
	self.ignoreUpUntilRelease = true
	self.ignoreDownUntilRelease = true
	self:updateImage()
end

return Player

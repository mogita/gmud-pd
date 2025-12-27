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

-- Player state constants
local STATE_IDLE <const> = "idle"
local STATE_WALKING <const> = "walking"
local STATE_AUTO_WALKING <const> = "auto_walking"

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
---@field state string Current player state (STATE_IDLE, STATE_WALKING, STATE_AUTO_WALKING)
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

	-- State machine
	self.state = STATE_IDLE

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

---Gather input from buttons
---@return table input Input state table
function Player:gatherInput()
	return {
		left = playdate.buttonIsPressed(playdate.kButtonLeft),
		right = playdate.buttonIsPressed(playdate.kButtonRight),
		up = playdate.buttonIsPressed(playdate.kButtonUp),
		down = playdate.buttonIsPressed(playdate.kButtonDown),
		b = playdate.buttonIsPressed(playdate.kButtonB),
		a = playdate.buttonIsPressed(playdate.kButtonA),
	}
end

---State handler for IDLE state
local idleState = {
	enter = function(self)
		-- Set standing frame based on current facing
		if self.currentFrame == FRAME_BACK or self.currentFrame == FRAME_FRONT then
			-- Keep facing up/down frame
		else
			self.currentFrame = FRAME_STAND_RIGHT
		end
		self.animFrameCounter = 0
	end,

	update = function(self, input)
		-- Priority 1: Up/Down changes facing
		if input.up and not self.ignoreUpUntilRelease then
			self.currentFrame = FRAME_BACK
			self.animFrameCounter = 0
			return STATE_IDLE -- Stay in idle
		elseif input.down and not self.ignoreDownUntilRelease then
			self.currentFrame = FRAME_FRONT
			self.animFrameCounter = 0
			return STATE_IDLE -- Stay in idle
		end

		-- Priority 2: B + Left/Right starts auto-walk
		if input.b and input.left and not self.wasMovingLeft then
			self.facing = DIR_LEFT
			return STATE_AUTO_WALKING
		elseif input.b and input.right and not self.wasMovingRight then
			self.facing = DIR_RIGHT
			return STATE_AUTO_WALKING
		end

		-- Priority 3: Left/Right starts manual walk
		if input.left and not input.b then
			self.facing = DIR_LEFT
			return STATE_WALKING
		elseif input.right and not input.b then
			self.facing = DIR_RIGHT
			return STATE_WALKING
		end

		-- Stay in idle
		return STATE_IDLE
	end,
}

---State handler for WALKING state
local walkingState = {
	enter = function(self)
		self.currentFrame = FRAME_WALK_RIGHT
		self.animFrameCounter = 0
	end,

	update = function(self, input)
		-- Priority 1: Up/Down transitions to idle
		if input.up and not self.ignoreUpUntilRelease then
			self.currentFrame = FRAME_BACK
			return STATE_IDLE
		elseif input.down and not self.ignoreDownUntilRelease then
			self.currentFrame = FRAME_FRONT
			return STATE_IDLE
		end

		-- Priority 2: B pressed starts auto-walk
		if input.b then
			return STATE_AUTO_WALKING
		end

		-- Priority 3: Check if still moving in the same direction
		local movingInDirection = (self.facing == DIR_LEFT and input.left) or (self.facing == DIR_RIGHT and input.right)
		if not movingInDirection then
			-- Direction released, go to idle
			return STATE_IDLE
		end

		-- Continue walking
		if self.facing == DIR_LEFT then
			self.worldX -= self.moveSpeed
		else
			self.worldX += self.moveSpeed
		end

		-- Animate
		local justPressed = (self.facing == DIR_LEFT and not self.wasMovingLeft)
			or (self.facing == DIR_RIGHT and not self.wasMovingRight)
		self:toggleWalkFrame(justPressed)

		return STATE_WALKING
	end,
}

---State handler for AUTO_WALKING state
local autoWalkingState = {
	enter = function(self)
		self.currentFrame = FRAME_WALK_RIGHT
		self.animFrameCounter = 0
	end,

	update = function(self, input)
		-- Calculate boundaries
		local minX = self.halfWidth
		local maxX = self.mapWidth - self.halfWidth

		-- Priority 1: Up/Down transitions to idle
		if input.up and not self.ignoreUpUntilRelease then
			self.currentFrame = FRAME_BACK
			return STATE_IDLE
		elseif input.down and not self.ignoreDownUntilRelease then
			self.currentFrame = FRAME_FRONT
			return STATE_IDLE
		end

		-- Priority 2: Left/Right without B transitions to manual walking
		if input.left and not input.b then
			self.facing = DIR_LEFT
			return STATE_WALKING
		elseif input.right and not input.b then
			self.facing = DIR_RIGHT
			return STATE_WALKING
		end

		-- Priority 3: B + opposite direction changes auto-walk direction
		if input.b and input.left and self.facing == DIR_RIGHT then
			self.facing = DIR_LEFT
		elseif input.b and input.right and self.facing == DIR_LEFT then
			self.facing = DIR_RIGHT
		end

		-- Continue auto-walking
		if self.facing == DIR_LEFT then
			self.worldX -= self.moveSpeed
		else
			self.worldX += self.moveSpeed
		end

		-- Animate
		self:toggleWalkFrame(false)

		-- Check if reached edge
		if self.worldX <= minX or self.worldX >= maxX then
			self.currentFrame = FRAME_STAND_RIGHT
			return STATE_IDLE
		end

		return STATE_AUTO_WALKING
	end,
}

---State handlers table
local stateHandlers = {
	[STATE_IDLE] = idleState,
	[STATE_WALKING] = walkingState,
	[STATE_AUTO_WALKING] = autoWalkingState,
}

---Change player state
---@param newState string The new state to transition to
function Player:changeState(newState)
	if self.state == newState then
		return
	end

	-- Call exit handler if it exists
	local oldHandler = stateHandlers[self.state]
	if oldHandler and oldHandler.exit then
		oldHandler.exit(self)
	end

	-- Change state
	self.state = newState

	-- Call enter handler if it exists
	local newHandler = stateHandlers[self.state]
	if newHandler and newHandler.enter then
		newHandler.enter(self)
	end
end

---Handle player input and movement (FSM-based)
function Player:update()
	-- Don't process movement if player is disabled (e.g., during dialog)
	if not self.canMove then
		return
	end

	-- Gather input
	local input = self:gatherInput()

	-- Clear ignore flags when buttons are released
	if not input.up then
		self.ignoreUpUntilRelease = false
	end
	if not input.down then
		self.ignoreDownUntilRelease = false
	end

	-- Get current state handler
	local handler = stateHandlers[self.state]
	if not handler then
		error("Invalid player state: " .. tostring(self.state))
	end

	-- Update state and get next state
	local nextState = handler.update(self, input)

	-- Transition to next state if different
	if nextState and nextState ~= self.state then
		self:changeState(nextState)
	end

	-- Update wasMoving flags for next frame
	self.wasMovingLeft = input.left
	self.wasMovingRight = input.right

	-- Clamp player position to map boundaries
	local minX = self.halfWidth
	local maxX = self.mapWidth - self.halfWidth

	if self.worldX < minX then
		self.worldX = minX
	elseif self.worldX > maxX then
		self.worldX = maxX
	end

	-- Update camera if player is moving
	if self.state == STATE_WALKING or self.state == STATE_AUTO_WALKING then
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

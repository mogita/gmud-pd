import("CoreLibs/graphics")
import("CoreLibs/sprites")
import("text/dialog-box")

local gfx <const> = playdate.graphics

-- Import modules
local Camera = import("camera")
local Player = import("player")
local Map = import("map")
local POIManager = import("poi-manager")

-- Game configuration
local MAP_SCALE <const> = 2.0 -- Scale factor for the map (1.0 = original size, 2.0 = double size)

-- Layout constants (screen height = 240px)
-- Stack containers vertically like CSS flexbox with flex-direction: column
local MAP_AREA_HEIGHT <const> = 108 -- Map container height
local PLAYER_AREA_HEIGHT <const> = 32 -- Player container height
local DIALOG_AREA_HEIGHT <const> = 100 -- Dialog container height (70px box + 10px margins + ~20px name tag)

-- Container boundaries (stacked vertically)
local MAP_TOP <const> = 0
local MAP_BOTTOM <const> = MAP_TOP + MAP_AREA_HEIGHT -- y=98

local PLAYER_TOP <const> = MAP_BOTTOM -- y=98
local PLAYER_BOTTOM <const> = PLAYER_TOP + PLAYER_AREA_HEIGHT -- y=130

local DIALOG_TOP <const> = PLAYER_BOTTOM -- y=130
local DIALOG_BOTTOM <const> = DIALOG_TOP + DIALOG_AREA_HEIGHT -- y=240

-- Y positions for elements
local MAP_BOTTOM_Y <const> = MAP_BOTTOM -- Map image bottom aligns at y=98
local PLAYER_Y <const> = PLAYER_BOTTOM -- Player sprite bottom at y=130 (with bottom-center anchor)

-- Game state
local camera
local player
local map
local dialog
local poiManager

-- Initialize game
function initialize()
	-- Set to maximum frame rate for smoother movement (default is 30, max is 50)
	playdate.display.setRefreshRate(30)

	-- Create map with image background
	map = Map.new({
		imagePath = "images/maps/1", -- Load map image (758x80px native)
		camera = nil, -- Will be set after camera is created
		scale = MAP_SCALE,
		bottomY = MAP_BOTTOM_Y, -- Map bottom aligns with player top (y=208)
	})

	-- Create camera with 100px scroll trigger offset
	-- Use the scaled map width
	camera = Camera.new({
		mapWidth = map:getWidth(), -- Use scaled map width
		scrollTriggerOffset = 100,
	})

	-- Set the camera reference in the map
	map.camera = camera

	-- Set up background drawing callback for the sprite system
	-- This ensures the map is drawn as part of the sprite update cycle
	gfx.sprite.setBackgroundDrawingCallback(function(x, y, width, height)
		-- Clear the background area with white
		gfx.setColor(gfx.kColorWhite)
		gfx.fillRect(x, y, width, height)

		-- Draw the map (it will handle its own positioning based on camera)
		map:draw()

		-- Draw POI debug visualization (if enabled)
		if poiManager then
			poiManager:drawDebug(camera)
		end
	end)

	-- Create player character (xiaoshutong)
	-- Uses spritesheet: gmud-player-1-table-32-32.png (4 frames of 32x32)
	player = Player.new({
		imagePath = "images/characters/gmud-player-1",
		startX = 20, -- Start at left side of map
		startY = PLAYER_Y, -- Player center Y position (224, with bottom at 240)
		moveSpeed = 2,
		mapWidth = map:getWidth(), -- Use scaled map width
		camera = camera,
		animSpeedRatio = 9, -- Animation speed: higher = slower (1 = every frame, 3 = every 3 frames, etc.)
	})
	player:add()

	-- Create dialog box sprite
	dialog = DialogBox.new({
		dialogs = {
			{
				speaker = "小书童",
				text = "顾炎武今日不在武馆，请给我糖葫芦，我会将毛笔给你。若想要切磋，请与旁边的何铁手交谈。若无其他要事，我就去忙了。",
			},
			{
				speaker = "顾炎武的大毛猫咪",
				text = "原来如此，多谢告知。",
			},
		},
	})
	dialog:add()

	-- Create POI manager
	poiManager = POIManager.new()

	-- Register named action handlers here if needed:
	-- poiManager:registerAction("handlerName", function(player, poi, manager) ... end)

	-- Load POIs for the initial map
	poiManager:loadForMap("map1")

	-- Debug: visualize POI positions (disable for production)
	poiManager:setDebugDrawParams(MAP_BOTTOM_Y, 3)
	poiManager:setDebugMode(true)

	-- Clear screen once at startup
	gfx.clear()
end

-- Initialize the game
initialize()

-- Track camera offset to trigger background redraw when camera moves
local lastCameraOffset = 0

---@diagnostic disable-next-line: duplicate-set-field
function playdate.update()
	-- Disable player movement when dialog is visible
	player:setCanMove(not dialog:isVisible())

	-- Update player movement
	player:update()

	-- Update POI manager with player position
	local playerX, _ = player:getWorldPosition()
	poiManager:updatePlayerPosition(playerX, player.halfWidth * 2)

	-- Check for POI interactions
	if not dialog:isVisible() then
		-- A button: interactive objects and NPCs
		if playdate.buttonJustPressed(playdate.kButtonA) then
			poiManager:tryTrigger(player, "A")
		-- UP button: passages (doors, paths)
		elseif playdate.buttonJustPressed(playdate.kButtonUp) then
			poiManager:tryTrigger(player, "up")
		-- DOWN button: exits
		elseif playdate.buttonJustPressed(playdate.kButtonDown) then
			poiManager:tryTrigger(player, "down")
		end
	else
		-- Dialog is visible, A advances it
		if playdate.buttonJustPressed(playdate.kButtonA) then
			dialog:next()
		end
	end

	-- Check if camera moved - if so, mark background as dirty
	local currentCameraOffset = camera:getOffset()
	if currentCameraOffset ~= lastCameraOffset then
		gfx.sprite.redrawBackground()
		lastCameraOffset = currentCameraOffset
	end

	-- Update sprites (includes player, dialog box, and background)
	gfx.sprite.update()
end

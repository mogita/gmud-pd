import("CoreLibs/graphics")
import("CoreLibs/sprites")
import("text/dialog-box")

local gfx <const> = playdate.graphics

-- Import modules
local Camera = import("camera")
local Player = import("player")
local Map = import("map")

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
	end)

	-- Create player character (xiaoshutong)
	player = Player.new({
		imagePath = "images/xiao-shu-tong.png",
		startX = 20, -- Start at left side of map
		startY = PLAYER_Y, -- Player center Y position (224, with bottom at 240)
		moveSpeed = 2,
		mapWidth = map:getWidth(), -- Use scaled map width
		camera = camera,
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

	-- Check if camera moved - if so, mark background as dirty
	local currentCameraOffset = camera:getOffset()
	if currentCameraOffset ~= lastCameraOffset then
		-- Redraw the background when camera moves
		gfx.sprite.redrawBackground()
		lastCameraOffset = currentCameraOffset
	end

	-- Update sprites (includes player, dialog box, and background)
	-- The background drawing callback will be called automatically
	gfx.sprite.update()

	-- Handle dialog input
	if playdate.buttonJustPressed(playdate.kButtonA) then
		if dialog:isVisible() then
			dialog:next()
		else
			dialog:show()
		end
	end
end

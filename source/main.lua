import("CoreLibs/graphics")
import("CoreLibs/sprites")
import("text/dialog-box")

local gfx <const> = playdate.graphics

-- Import modules
local Camera = import("camera")
local Player = import("player")
local Map = import("map")

-- Game state
local camera
local player
local map
local dialog

-- Initialize game
function initialize()
	-- Set to maximum frame rate for smoother movement (default is 30)
	playdate.display.setRefreshRate(50)

	-- Create camera with 100px scroll trigger offset
	camera = Camera.new({
		mapWidth = 758, -- Map width from image (758px)
		scrollTriggerOffset = 100,
	})

	-- Create map with image background
	map = Map.new({
		imagePath = "images/maps/1", -- Load map image (758x80px)
		camera = camera,
	})

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
		startX = 50, -- Start at left side of map
		startY = 120, -- Bottom of upper half (player's horizontal line)
		moveSpeed = 2,
		mapWidth = 758, -- Match map width
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

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
	-- Create camera with 100px scroll trigger offset
	camera = Camera.new({
		mapWidth = 1200, -- Map is 3x screen width
		scrollTriggerOffset = 100,
	})

	-- Create map with repeating pattern background
	map = Map.new({
		width = 1200,
		camera = camera,
	})

	-- Create player character (xiaoshutong)
	player = Player.new({
		imagePath = "images/xiao-shu-tong.png",
		startX = 50, -- Start at left side of map
		startY = 120, -- Bottom of upper half
		moveSpeed = 3,
		mapWidth = 1200,
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

---@diagnostic disable-next-line: duplicate-set-field
function playdate.update()
	-- Draw map background (upper half)
	map:draw()

	-- Disable player movement when dialog is visible
	player:setCanMove(not dialog:isVisible())

	-- Update player movement
	player:update()

	-- Update sprites (includes player and dialog box)
	-- This only redraws dirty rects, not the entire screen!
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

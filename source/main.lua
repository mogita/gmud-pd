import("CoreLibs/graphics")
import("CoreLibs/sprites")
import("text/dialog-box")

local gfx <const> = playdate.graphics

-- Create character sprite
local characterSprite = gfx.sprite.new()
local characterImage = gfx.image.new("images/xiao-shu-tong.png")
if characterImage then
	characterSprite:setImage(characterImage)
	characterSprite:moveTo(180, 100)
	characterSprite:add()
else
	print("Warning: Failed to load character image")
end

-- Create dialog box sprite
local dialog = DialogBox.new({
	dialogs = {
		{
			speaker = "小书童",
			text = "顾炎武今日不在武馆，请给我糖葫芦，我会将毛笔给你。若想要切磋，请与旁边的何铁手交谈。若无其他要事，我就去忙了。刚才我们在函数详解这说了四个点，现在我们来说明第五个点。我定义一个变量 num 1，接下来我调用一个方法，把 10 和 20 传进去。",
		},
		{
			speaker = "顾炎武",
			text = "原来如此，多谢告知。",
		},
	},
	speed = "fast", -- "instant", "fast", "slow"
	fontSize = "medium", -- "small" (12px), "medium" (16px), "large" (18px)
	invert = false,
})

-- Add dialog sprite to display list
dialog:add()

-- Clear screen once at startup
gfx.clear()

---@diagnostic disable-next-line: duplicate-set-field
function playdate.update()
	-- Update sprites (includes character and dialog box)
	-- This only redraws dirty rects, not the entire screen!
	gfx.sprite.update()

	-- Handle input
	if playdate.buttonJustPressed(playdate.kButtonA) or playdate.buttonJustPressed(playdate.kButtonDown) then
		if dialog:isVisible() then
			dialog:next()
		else
			dialog:show()
		end
	end
end

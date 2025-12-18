import("text/draw")

local gfx <const> = playdate.graphics
local font_12 = gfx.font.new("fonts/fusion-pixel-font-12px")
local font_16 = gfx.font.new("fonts/source-han-sans-cn-16px")
local font_18 = gfx.font.new("fonts/source-han-serif-cn-semibold-18px")

function DrawMessageBox(text, x, y, w, h, padding)
	if padding == nil then
		padding = 6
	end

	local tx = x + padding
	local ty = y + padding
	local tw = w - padding * 2
	local th = h - padding * 2

	local tw2, th2 = gfx.getTextSize(text:gsub("\n", ""))

	-- draw dialogue box
	gfx.drawRoundRect(x, y, w, h, 8)

	-- debug: draw text-drawing area
	-- gfx.drawRect(tx, ty, tw2, th2)

	-- draw text
	drawTextArea(text, 1.2, 0, font_12, gfx.kDrawModeCopy, tx, ty, tw, th)
end

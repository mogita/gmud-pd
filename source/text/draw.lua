import "CoreLibs/graphics"

local gfx <const> = playdate.graphics

local function _stringToTable(str)
	local tbl = {}
	for char in string.gmatch(str, "[%z\1-\127\194-\244][\128-\191]*") do
		table.insert(tbl, char)
	end
	return tbl
end

local function _findNextSpaceIndex(tbl, index)
	if index >= #tbl then
		return -1
	end
	for i = index + 1, #tbl do
		if tbl[i] == " " then
			if i > 12 then  --max line break char length
				return -1
			else
				return i
			end
		end
	end
	return -1
end

function drawTextArea(text, line_height_factor, char_kerning, font, draw_mode, start_x, start_y, width, height)
	-- example:
	-- draw_text_area({"你","好"}, 1.6, 0, gfx.font.new('font/SourceHanSansCN-M-20px'), playdate.graphics.kDrawModeCopy, 0, 0, 300, 200)
	--
	-- return:
	-- char_offset: how many chars has been drawn

	local char_offset = 1
	local current_x = start_x
	local current_y = start_y
	gfx.setFont(font)
	gfx.setImageDrawMode(draw_mode)
	local max_zh_char_size = gfx.getTextSize("啊") + char_kerning
	local line_height = max_zh_char_size * line_height_factor
	local text_tbl = _stringToTable(text)

	local function _linebreak_offset()
		current_x = start_x
		current_y += line_height
	end
	
	-- If height is less than one line height, set it to one line height
	if height < line_height then
		height = line_height
	end

	for key, char in pairs(text_tbl) do
		if current_y > start_y + height - line_height then
			break
		end

		if char == "\n" then
			_linebreak_offset()
		else
			if char == " " then  --word break
				local next_space_index = _findNextSpaceIndex(text_tbl, key)
				local word_width = 0
				if next_space_index > 1 and next_space_index > key then
					for i = key+1, next_space_index do
						word_width += gfx.getTextSize(text_tbl[i]) + char_kerning
					end
					if current_x + word_width > start_x + width - max_zh_char_size then
						_linebreak_offset()
					end
				end
			end
			
			gfx.drawTextAligned(char, current_x, current_y, kTextAlignment.left)
			current_x += gfx.getTextSize(char) + char_kerning
		end
		
		if current_x > start_x + width - max_zh_char_size then
			_linebreak_offset()
		end

		char_offset += 1
	end

	return char_offset
end
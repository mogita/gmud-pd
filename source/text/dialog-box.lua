import("CoreLibs/sprites")

local gfx <const> = playdate.graphics

-- Speed constants (milliseconds per character)
local SPEED_VALUES = {
	instant = 0,
	fast = 20,
	slow = 60,
}

-- Font size presets
local FONT_PRESETS = {
	small = gfx.font.new("fonts/fusion-pixel-font-12px"),
	medium = gfx.font.new("fonts/source-han-sans-cn-16px"),
	large = gfx.font.new("fonts/source-han-serif-cn-semibold-18px"),
}

---@class DialogEntry
---@field speaker string The name of the speaker
---@field text string The dialog text content

---@class DialogBoxConfig
---@field dialogs DialogEntry[] Array of dialog entries
---@field speed? "instant"|"fast"|"slow" Text display speed (default: "fast")
---@field fontSize? "small"|"medium"|"large" Font size preset (default: "medium")
---@field invert? boolean Dark background mode (default: false)
---@field onComplete? function Callback when all dialogs finish
---@field font? any Custom font for dialog text (overrides fontSize)
---@field nameFont? any Custom font for speaker name (overrides fontSize)
---@field marginX? number Horizontal margin from screen edge (default: 10)
---@field marginY? number Vertical margin from screen edge (default: 10)
---@field boxHeight? number Height of dialog box (default: 80)
---@field padding? number Inner padding of dialog box (default: 10)
---@field nameTagPadding? number Inner padding of name tag (default: 6)
---@field nameTagOverlap? number Overlap between name tag and dialog box (default: 8)
---@field cornerRadius? number Corner radius for rounded rectangles (default: 8)
---@field lineHeightFactor? number Line height multiplier (default: 1.3)
---@field charKerning? number Character spacing (default: 0)

---@class DialogBox : playdate.graphics.sprite
---@field dialogs DialogEntry[]
---@field speed number
---@field invert boolean
---@field onComplete function
---@field currentDialogIndex number
---@field currentPageIndex number
---@field pages string[]
---@field displayedCharCount number
---@field isAnimating boolean
---@field font any
---@field nameFont any
---@field marginX number
---@field marginY number
---@field boxHeight number
---@field padding number
---@field nameTagPadding number
---@field nameTagOverlap number
---@field cornerRadius number
---@field lineHeightFactor number
---@field charKerning number
---@field boxWidth number
---@field boxX number
---@field boxY number
---@field textWidth number
---@field textHeight number
---@field lastCharTime number
---@field new fun(config: DialogBoxConfig): DialogBox
---@field show fun(self: DialogBox)
---@field hide fun(self: DialogBox)
---@field next fun(self: DialogBox)
---@field update fun(self: DialogBox)
---@field draw fun(self: DialogBox, x: number, y: number, width: number, height: number)
---@field isTextAnimating fun(self: DialogBox): boolean
---@field getCurrentInfo fun(self: DialogBox): table
---@field _prepareCurrentDialog fun(self: DialogBox)

DialogBox = {}
DialogBox.__index = DialogBox

-- Make DialogBox extend gfx.sprite
setmetatable(DialogBox, {
	__index = gfx.sprite,
})

-- Default configuration
local DEFAULT_CONFIG = {
	marginX = 10,
	marginY = 10,
	boxHeight = 90,
	padding = 10,
	nameTagPadding = 6,
	nameTagOverlap = 8,
	cornerRadius = 8,
	lineHeightFactor = 1.3,
	charKerning = 0,
}

-- Helper: convert UTF-8 string to character table
local function stringToTable(str)
	local tbl = {}
	for char in string.gmatch(str, "[%z\1-\127\194-\244][\128-\191]*") do
		table.insert(tbl, char)
	end
	return tbl
end

-- Helper: convert page (array of lines) to text
local function pageToText(page)
	if type(page) == "table" then
		return table.concat(page, "\n")
	end
	return page or ""
end

-- Get substring of UTF-8 text by character count
local function getDisplayedText(text, charCount)
	local chars = stringToTable(text)
	local result = {}
	for i = 1, math.min(charCount, #chars) do
		table.insert(result, chars[i])
	end
	return table.concat(result)
end

-- Calculate how many characters fit in one page
local function calculatePageCapacity(font, width, height, lineHeightFactor, charKerning)
	gfx.setFont(font)
	local maxCharSize = gfx.getTextSize("啊") + charKerning
	local lineHeight = maxCharSize * lineHeightFactor
	local charsPerLine = math.floor(width / maxCharSize)
	local linesPerPage = math.floor(height / lineHeight)
	return charsPerLine, linesPerPage, lineHeight, maxCharSize
end

-- Split text into pages based on available space
-- Returns array of pages, where each page is an array of lines
local function paginateText(text, font, width, height, lineHeightFactor, charKerning)
	local chars = stringToTable(text)
	local pages = {}
	local _, linesPerPage = calculatePageCapacity(font, width, height, lineHeightFactor, charKerning)

	gfx.setFont(font)
	local currentPage = {}
	local currentLine = ""
	local currentLineWidth = 0

	for _, char in ipairs(chars) do
		if char == "\n" then
			-- Explicit newline
			table.insert(currentPage, currentLine)
			currentLine = ""
			currentLineWidth = 0

			-- Check if page is full
			if #currentPage >= linesPerPage then
				table.insert(pages, currentPage)
				currentPage = {}
			end
		else
			local charWidth = gfx.getTextSize(char) + charKerning
			if currentLineWidth + charWidth > width then
				-- Line overflow - wrap to next line
				table.insert(currentPage, currentLine)
				currentLine = char
				currentLineWidth = charWidth

				-- Check if page is full
				if #currentPage >= linesPerPage then
					table.insert(pages, currentPage)
					currentPage = {}
				end
			else
				-- Add character to current line
				currentLine = currentLine .. char
				currentLineWidth += charWidth
			end
		end
	end

	-- Add remaining content
	if #currentLine > 0 then
		table.insert(currentPage, currentLine)
	end
	if #currentPage > 0 then
		table.insert(pages, currentPage)
	end

	-- Ensure at least one page
	if #pages == 0 then
		pages = { {} }
	end

	return pages
end

-- DialogBox class
---@param config DialogBoxConfig Configuration for the dialog box
---@return DialogBox
function DialogBox.new(config)
	-- Create sprite instance and cast to DialogBox type
	---@type DialogBox
	---@diagnostic disable-next-line: assign-type-mismatch
	local self = gfx.sprite.new()
	setmetatable(self, DialogBox)

	-- Merge config with defaults
	self.dialogs = config.dialogs or {}
	local speedKey = config.speed or "fast"
	self.speed = SPEED_VALUES[speedKey] or SPEED_VALUES.fast
	self.invert = config.invert or false
	self.onComplete = config.onComplete or function() end

	-- Handle font size presets
	local fontSizeKey = config.fontSize or "medium"
	local defaultFont = FONT_PRESETS[fontSizeKey] or FONT_PRESETS.medium
	self.font = config.font or defaultFont
	self.nameFont = config.nameFont or defaultFont
	self.marginX = config.marginX or DEFAULT_CONFIG.marginX
	self.marginY = config.marginY or DEFAULT_CONFIG.marginY
	self.boxHeight = config.boxHeight or DEFAULT_CONFIG.boxHeight
	self.padding = config.padding or DEFAULT_CONFIG.padding
	self.nameTagPadding = config.nameTagPadding or DEFAULT_CONFIG.nameTagPadding
	self.nameTagOverlap = config.nameTagOverlap or DEFAULT_CONFIG.nameTagOverlap
	self.cornerRadius = config.cornerRadius or DEFAULT_CONFIG.cornerRadius
	self.lineHeightFactor = config.lineHeightFactor or DEFAULT_CONFIG.lineHeightFactor
	self.charKerning = config.charKerning or DEFAULT_CONFIG.charKerning

	-- State
	self.currentDialogIndex = 1
	self.currentPageIndex = 1
	self.pages = {}
	self.displayedCharCount = 0
	self.isAnimating = false
	self.lastCharTime = 0

	-- Calculate dimensions
	self.boxWidth = 400 - (self.marginX * 2)
	self.boxX = self.marginX
	self.boxY = 240 - self.marginY - self.boxHeight
	self.textWidth = self.boxWidth - (self.padding * 2)
	self.textHeight = self.boxHeight - (self.padding * 2)

	-- Set sprite bounds (includes name tag area above the box)
	local nameTagHeight = 30 -- Approximate max height for name tag
	local totalHeight = self.boxHeight + nameTagHeight
	self:setBounds(0, self.boxY - nameTagHeight, 400, totalHeight)
	self:setCenter(0, 0) -- Use top-left as anchor point
	self:moveTo(0, self.boxY - nameTagHeight)
	self:setZIndex(1000) -- Draw on top of other sprites

	-- Start hidden
	self:setVisible(false)

	return self
end

-- Show the dialog box and start from the first dialog
function DialogBox:show()
	self:setVisible(true)
	self.currentDialogIndex = 1
	self.currentPageIndex = 1
	self:_prepareCurrentDialog()
end

-- Hide the dialog box
function DialogBox:hide()
	self:setVisible(false)
end

-- Check if dialog box is visible (override to use sprite's isVisible)
-- Note: We don't need to override this - just use the sprite's built-in isVisible() method

-- Check if text is still animating (typewriter effect)
function DialogBox:isTextAnimating()
	return self.isAnimating
end

-- Prepare pages for current dialog entry
function DialogBox:_prepareCurrentDialog()
	if self.currentDialogIndex > #self.dialogs then
		return
	end

	local dialog = self.dialogs[self.currentDialogIndex]
	self.pages =
		paginateText(dialog.text, self.font, self.textWidth, self.textHeight, self.lineHeightFactor, self.charKerning)
	self.currentPageIndex = 1
	self.displayedCharCount = 0
	self.lastCharTime = playdate.getCurrentTimeMilliseconds()

	if self.speed == 0 then
		local pageText = pageToText(self.pages[self.currentPageIndex])
		self.displayedCharCount = #stringToTable(pageText)
		self.isAnimating = false
	else
		self.isAnimating = true
	end

	-- Mark sprite as dirty since content changed
	self:markDirty()
end

-- Advance to next page or next dialog
function DialogBox:next()
	if not self:isVisible() then
		return
	end

	-- If still animating, complete the current page instantly
	if self.isAnimating then
		local pageText = pageToText(self.pages[self.currentPageIndex])
		self.displayedCharCount = #stringToTable(pageText)
		self.isAnimating = false
		self:markDirty()
		return
	end

	-- Move to next page
	if self.currentPageIndex < #self.pages then
		self.currentPageIndex += 1
		self.displayedCharCount = 0
		self.lastCharTime = playdate.getCurrentTimeMilliseconds()
		if self.speed ~= 0 then
			self.isAnimating = true
		else
			local pageText = pageToText(self.pages[self.currentPageIndex])
			self.displayedCharCount = #stringToTable(pageText)
		end
		self:markDirty()
		return
	end

	-- Move to next dialog
	if self.currentDialogIndex < #self.dialogs then
		self.currentDialogIndex += 1
		self:_prepareCurrentDialog()
		return
	end

	-- All dialogs complete
	self:setVisible(false)
	self.onComplete()
end

-- Update typewriter animation (override sprite's update method)
function DialogBox:update()
	if not self:isVisible() or not self.isAnimating then
		return
	end

	local currentTime = playdate.getCurrentTimeMilliseconds()
	local elapsed = currentTime - self.lastCharTime

	if elapsed >= self.speed then
		local pageText = pageToText(self.pages[self.currentPageIndex])
		local totalChars = #stringToTable(pageText)

		self.displayedCharCount += 1
		self.lastCharTime = currentTime

		if self.displayedCharCount >= totalChars then
			self.displayedCharCount = totalChars
			self.isAnimating = false
		end

		-- Mark sprite as dirty since displayed text changed
		self:markDirty()
	end
end

-- Draw the dialog box (sprite draw callback)
-- Note: Sprite draw callbacks receive (x, y, width, height) dirty rect parameters
-- but we don't use them since we always draw the full dialog box
---@diagnostic disable-next-line: unused-local
function DialogBox:draw(x, y, width, height)
	local dialog = self.dialogs[self.currentDialogIndex]
	if not dialog then
		return
	end

	local bgColor = self.invert and gfx.kColorBlack or gfx.kColorWhite
	local fgColor = self.invert and gfx.kColorWhite or gfx.kColorBlack
	local drawMode = self.invert and gfx.kDrawModeInverted or gfx.kDrawModeCopy

	-- Calculate sprite-local coordinates
	-- The sprite's top-left is at (0, 0) in sprite coordinates
	-- We need to offset from screen coordinates to sprite-local coordinates
	local nameTagHeight = 30 -- Same as in new()
	local localBoxX = self.boxX
	local localBoxY = nameTagHeight -- Box starts at nameTagHeight in sprite-local coords

	-- Draw main dialog box background
	gfx.setColor(bgColor)
	gfx.fillRoundRect(localBoxX, localBoxY, self.boxWidth, self.boxHeight, self.cornerRadius)

	-- Draw main dialog box border
	gfx.setColor(fgColor)
	gfx.drawRoundRect(localBoxX, localBoxY, self.boxWidth, self.boxHeight, self.cornerRadius)

	-- Draw name tag if speaker exists
	if dialog.speaker and #dialog.speaker > 0 then
		gfx.setFont(self.nameFont)
		local nameWidth, nameHeight = gfx.getTextSize(dialog.speaker)
		local tagWidth = nameWidth + (self.nameTagPadding * 2)
		local tagHeight = nameHeight + (self.nameTagPadding * 2)
		local tagX = localBoxX + self.padding
		local tagY = localBoxY - tagHeight + self.nameTagOverlap

		-- Name tag background
		gfx.setColor(bgColor)
		gfx.fillRoundRect(tagX, tagY, tagWidth, tagHeight, self.cornerRadius / 2)

		-- Name tag border
		gfx.setColor(fgColor)
		gfx.drawRoundRect(tagX, tagY, tagWidth, tagHeight, self.cornerRadius / 2)

		-- Name text
		gfx.setImageDrawMode(drawMode)
		gfx.drawText(dialog.speaker, tagX + self.nameTagPadding, tagY + self.nameTagPadding)
	end

	-- Draw dialog text
	local page = self.pages[self.currentPageIndex] or {}

	local textX = localBoxX + self.padding
	local textY = localBoxY + self.padding

	gfx.setFont(self.font)
	gfx.setImageDrawMode(drawMode)

	-- Calculate line height
	local maxCharSize = gfx.getTextSize("啊") + self.charKerning
	local lineHeight = maxCharSize * self.lineHeightFactor

	-- Draw text line by line
	local displayLines = {}
	if type(page) == "table" then
		-- Page is array of lines - reconstruct with proper character count
		local charsSoFar = 0
		for _, line in ipairs(page) do
			local lineChars = #stringToTable(line)
			if charsSoFar + lineChars + 1 <= self.displayedCharCount then -- +1 for \n
				table.insert(displayLines, line)
				charsSoFar += lineChars + 1
			elseif charsSoFar < self.displayedCharCount then
				-- Partial line
				local remainingChars = self.displayedCharCount - charsSoFar
				table.insert(displayLines, getDisplayedText(line, remainingChars))
				break
			else
				break
			end
		end
	end

	-- Render lines
	local currentY = textY
	for _, line in ipairs(displayLines) do
		gfx.drawText(line, textX, currentY)
		currentY += lineHeight
	end

	-- Draw "continue" arrow when not animating and there are more pages/dialogs
	local hasMore = self.currentPageIndex < #self.pages or self.currentDialogIndex < #self.dialogs
	if not self.isAnimating and hasMore then
		local indicatorX = localBoxX + self.boxWidth - self.padding - 8
		local indicatorY = localBoxY + self.boxHeight - self.padding - 4
		gfx.setColor(fgColor)
		gfx.fillTriangle(indicatorX, indicatorY - 6, indicatorX + 6, indicatorY - 6, indicatorX + 3, indicatorY)
	end
end

-- Get current dialog info (useful for debugging)
function DialogBox:getCurrentInfo()
	return {
		dialogIndex = self.currentDialogIndex,
		totalDialogs = #self.dialogs,
		pageIndex = self.currentPageIndex,
		totalPages = #self.pages,
		isAnimating = self.isAnimating,
	}
end

-- POI (Point of Interest) class
-- Represents an interactive area on the map

local Categories = import("poi/categories")

-- Valid category values for validation
local ValidCategories = {
	[Categories.Category.INTERACTIVE] = true,
	[Categories.Category.PASSAGE] = true,
	[Categories.Category.NPC] = true,
}

---@class POI
---@field id string Unique identifier
---@field category string POI category: "interactive", "passage", "npc"
---@field x number World X position (left edge of trigger area)
---@field width number Width of trigger area
---@field trigger string Trigger key: "A", "up", or "down"
---@field onTrigger function|nil Custom callback when triggered
---@field handlerName string|nil Named handler to use
---@field data table|nil Category-specific metadata
local POI = {}
POI.__index = POI

---Create a new POI
---@param config table POI configuration
---@return POI
function POI.new(config)
	local self = setmetatable({}, POI)

	-- Required fields
	assert(config.id, "POI requires an id")
	assert(config.x, "POI requires an x position")
	assert(config.width, "POI requires a width")
	assert(config.category, "POI '" .. config.id .. "' requires a category")

	-- Validate category
	if not ValidCategories[config.category] then
		error(
			"POI '"
				.. config.id
				.. "' has invalid category: '"
				.. tostring(config.category)
				.. "'. Must be one of: interactive, passage, npc"
		)
	end

	self.id = config.id
	self.x = config.x
	self.width = config.width
	self.category = config.category

	-- Trigger key (uses category default if not specified)
	self.trigger = config.trigger
	if not self.trigger then
		self.trigger = Categories.getDefaultTrigger(self.category)
	end

	-- Handler configuration
	self.onTrigger = config.onTrigger
	self.handlerName = config.handlerName

	-- Category-specific data
	self.data = config.data or {}

	return self
end

---Check if this POI responds to a given trigger
---@param triggerKey string The trigger to check ("A", "up", "down")
---@return boolean
function POI:respondsToTrigger(triggerKey)
	return self.trigger == triggerKey
end

---Check if a world X position is within this POI's trigger area
---@param worldX number The X position to check
---@param objectWidth number|nil Width of the object (default 0, point check)
---@return boolean
function POI:containsX(worldX, objectWidth)
	objectWidth = objectWidth or 0
	local halfWidth = objectWidth / 2

	-- Object's left and right edges
	local objLeft = worldX - halfWidth
	local objRight = worldX + halfWidth

	-- POI's left and right edges
	local poiLeft = self.x
	local poiRight = self.x + self.width

	-- Check for overlap
	return objRight >= poiLeft and objLeft <= poiRight
end

---Get the center X position of this POI
---@return number
function POI:getCenterX()
	return self.x + self.width / 2
end

return POI

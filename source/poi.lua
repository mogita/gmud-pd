-- POI (Point of Interest) class
-- Represents an interactive area on the map

---@class POI
---@field id string Unique identifier
---@field type string Category: "well", "door", "npc", "passage", etc.
---@field x number World X position (left edge of trigger area)
---@field width number Width of trigger area
---@field action string Trigger key: "up" (interact) or "down" (exit)
---@field onTrigger function|nil Custom callback when triggered (optional if using named action)
---@field actionName string|nil Named action handler to use (optional if using onTrigger)
---@field data table|nil Optional metadata (dialog, destination, etc.)
local POI = {}
POI.__index = POI

---Create a new POI
---@param config {id: string, type: string, x: number, width: number, action: string, onTrigger: function?, actionName: string?, data: table?}
---@return POI
function POI.new(config)
	local self = setmetatable({}, POI)

	-- Required fields
	assert(config.id, "POI requires an id")
	assert(config.type, "POI requires a type")
	assert(config.x, "POI requires an x position")
	assert(config.width, "POI requires a width")
	assert(config.action == "up" or config.action == "down", "POI action must be 'up' or 'down'")

	self.id = config.id
	self.type = config.type
	self.x = config.x
	self.width = config.width
	self.action = config.action

	-- Optional fields (at least one of onTrigger or actionName should be provided)
	self.onTrigger = config.onTrigger
	self.actionName = config.actionName
	self.data = config.data or {}

	return self
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


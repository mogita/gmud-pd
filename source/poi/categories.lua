-- POI Categories and Trigger Keys
-- Defines the types of POIs and how they are activated

---@class POICategory
---@field INTERACTIVE string Objects player can interact with (A key)
---@field PASSAGE string Transitions to other locations (UP key)
---@field NPC string Characters with menu options (A key)

local Category = {
	INTERACTIVE = "interactive", -- Wells, signs, boards, etc.
	PASSAGE = "passage",         -- Doors, paths to other maps
	NPC = "npc",                 -- Characters with menus
}

---@class POITrigger
---@field A string A button trigger
---@field UP string D-pad up trigger
---@field DOWN string D-pad down trigger

local Trigger = {
	A = "A",
	UP = "up",
	DOWN = "down",
}

-- Default trigger key for each category
local CategoryDefaultTrigger = {
	[Category.INTERACTIVE] = Trigger.A,
	[Category.PASSAGE] = Trigger.UP,
	[Category.NPC] = Trigger.A,
}

---Get the default trigger for a category
---@param category string The POI category
---@return string trigger The default trigger key
local function getDefaultTrigger(category)
	return CategoryDefaultTrigger[category] or Trigger.A
end

return {
	Category = Category,
	Trigger = Trigger,
	getDefaultTrigger = getDefaultTrigger,
}


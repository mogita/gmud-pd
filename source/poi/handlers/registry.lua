-- POI Handler Registry Singleton
-- Separated from init.lua to avoid circular imports

---@class HandlerRegistry
---@field handlers table<string, function> Registered handlers by name
---@field categoryHandlers table<string, function> Default handlers by category
local HandlerRegistry = {}
HandlerRegistry.__index = HandlerRegistry

---Create a new handler registry
---@return HandlerRegistry
function HandlerRegistry.new()
	local self = setmetatable({}, HandlerRegistry)
	self.handlers = {}
	self.categoryHandlers = {}
	return self
end

---Register a named handler
---@param name string Handler name (e.g., "drink_water", "read_sign")
---@param handler function Handler function(player, poi, context)
function HandlerRegistry:register(name, handler)
	self.handlers[name] = handler
end

---Register a default handler for a category
---@param category string The POI category
---@param handler function Handler function(player, poi, context)
function HandlerRegistry:registerCategoryDefault(category, handler)
	self.categoryHandlers[category] = handler
end

---Get a handler by name
---@param name string Handler name
---@return function|nil handler
function HandlerRegistry:get(name)
	return self.handlers[name]
end

---Execute handler for a POI
---@param player table The player object
---@param poi POI The POI to handle
---@param context table|nil Additional context data
---@return boolean handled Whether the POI was handled
function HandlerRegistry:handle(player, poi, context)
	context = context or {}

	-- 1. Try POI's specific handler name
	if poi.handlerName and self.handlers[poi.handlerName] then
		self.handlers[poi.handlerName](player, poi, context)
		return true
	end

	-- 2. Try POI's inline onTrigger
	if poi.onTrigger then
		poi.onTrigger(player, poi, context)
		return true
	end

	-- 3. Try category default handler
	local category = poi.category
	if category and self.categoryHandlers[category] then
		self.categoryHandlers[category](player, poi, context)
		return true
	end

	return false
end

-- Create and export global registry instance
local registry = HandlerRegistry.new()

return {
	HandlerRegistry = HandlerRegistry,
	registry = registry,
}


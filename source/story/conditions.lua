-- Condition Evaluator
-- Evaluates conditions for story branching, quest availability, dialogue options, etc.

---@class Condition
---@field type string Condition type
---@field params table Condition parameters

---@class ConditionEvaluator
---@field state StoryState Reference to game state
---@field evaluators table<string, function> Registered condition evaluators
local ConditionEvaluator = {}
ConditionEvaluator.__index = ConditionEvaluator

---Create a new condition evaluator
---@param state StoryState The story state to evaluate against
---@return ConditionEvaluator
function ConditionEvaluator.new(state)
	local self = setmetatable({}, ConditionEvaluator)
	self.state = state
	self.evaluators = {}

	-- Register built-in condition types
	self:registerBuiltins()

	return self
end

---Register a condition evaluator
---@param conditionType string The condition type name
---@param evaluator function(params, state) -> boolean
function ConditionEvaluator:registerType(conditionType, evaluator)
	self.evaluators[conditionType] = evaluator
end

---Register built-in condition types
function ConditionEvaluator:registerBuiltins()
	-- Check if a flag is set
	self:registerType("hasFlag", function(params, state)
		return state:hasFlag(params.flag)
	end)

	-- Check if a flag is NOT set
	self:registerType("notFlag", function(params, state)
		return not state:hasFlag(params.flag)
	end)

	-- Check variable comparison
	self:registerType("varEquals", function(params, state)
		return state:getVar(params.var) == params.value
	end)

	self:registerType("varGreaterThan", function(params, state)
		local val = state:getVar(params.var, 0)
		return val > params.value
	end)

	self:registerType("varLessThan", function(params, state)
		local val = state:getVar(params.var, 0)
		return val < params.value
	end)

	-- Check quest status
	self:registerType("questStatus", function(params, state)
		return state:isQuestStatus(params.quest, params.status)
	end)

	-- Check quest step
	self:registerType("questStep", function(params, state)
		local quest = state:getQuest(params.quest)
		if params.atLeast then
			return quest.step >= params.atLeast
		elseif params.exactly then
			return quest.step == params.exactly
		end
		return false
	end)

	-- Check relationship level
	self:registerType("relationship", function(params, state)
		local rel = state:getRelationship(params.npc)
		if params.atLeast then
			return rel >= params.atLeast
		elseif params.atMost then
			return rel <= params.atMost
		end
		return true
	end)

	-- Check if player has item (placeholder)
	self:registerType("hasItem", function(params, state)
		-- TODO: Integrate with inventory system
		return state:hasFlag("has_" .. params.item)
	end)

	-- Always true/false (for testing)
	self:registerType("always", function(params, state)
		return true
	end)

	self:registerType("never", function(params, state)
		return false
	end)
end

---Evaluate a single condition
---@param condition Condition The condition to evaluate
---@return boolean result
function ConditionEvaluator:evaluate(condition)
	if not condition or not condition.type then
		return true -- No condition = always true
	end

	local evaluator = self.evaluators[condition.type]
	if not evaluator then
		print("[Condition] Unknown type: " .. condition.type)
		return false
	end

	return evaluator(condition.params or {}, self.state)
end

---Evaluate multiple conditions (all must be true)
---@param conditions Condition[] Array of conditions
---@return boolean result
function ConditionEvaluator:evaluateAll(conditions)
	if not conditions or #conditions == 0 then
		return true
	end

	for _, condition in ipairs(conditions) do
		if not self:evaluate(condition) then
			return false
		end
	end

	return true
end

---Evaluate multiple conditions (any must be true)
---@param conditions Condition[] Array of conditions
---@return boolean result
function ConditionEvaluator:evaluateAny(conditions)
	if not conditions or #conditions == 0 then
		return true
	end

	for _, condition in ipairs(conditions) do
		if self:evaluate(condition) then
			return true
		end
	end

	return false
end

return {
	ConditionEvaluator = ConditionEvaluator,
}


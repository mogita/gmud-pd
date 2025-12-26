-- Story System Initialization
-- Sets up the story state and condition evaluator

local StateModule = import("story/state")
local ConditionsModule = import("story/conditions")

---@class StorySystem
---@field state StoryState The game's story state
---@field conditions ConditionEvaluator Condition evaluator
local StorySystem = {}
StorySystem.__index = StorySystem

---Create a new story system
---@return StorySystem
function StorySystem.new()
	local self = setmetatable({}, StorySystem)

	self.state = StateModule.StoryState.new()
	self.conditions = ConditionsModule.ConditionEvaluator.new(self.state)

	return self
end

---Check if conditions are met
---@param conditions table[] Array of condition objects
---@return boolean
function StorySystem:checkConditions(conditions)
	return self.conditions:evaluateAll(conditions)
end

---Set a story flag
---@param flag string Flag name
function StorySystem:setFlag(flag)
	self.state:setFlag(flag)
end

---Check if a flag is set
---@param flag string Flag name
---@return boolean
function StorySystem:hasFlag(flag)
	return self.state:hasFlag(flag)
end

---Get a variable value
---@param name string Variable name
---@param default any Default value
---@return any
function StorySystem:getVar(name, default)
	return self.state:getVar(name, default)
end

---Set a variable value
---@param name string Variable name
---@param value any Value to set
function StorySystem:setVar(name, value)
	self.state:setVar(name, value)
end

---Get quest state
---@param questId string Quest identifier
---@return table
function StorySystem:getQuest(questId)
	return self.state:getQuest(questId)
end

---Start a quest
---@param questId string Quest identifier
function StorySystem:startQuest(questId)
	self.state:setQuestStatus(questId, StateModule.QuestStatus.ACTIVE)
end

---Complete a quest
---@param questId string Quest identifier
function StorySystem:completeQuest(questId)
	self.state:setQuestStatus(questId, StateModule.QuestStatus.COMPLETED)
end

---Export state for saving
---@return table
function StorySystem:export()
	return self.state:export()
end

---Import state from save
---@param data table Saved state data
function StorySystem:import(data)
	self.state:import(data)
end

return {
	StorySystem = StorySystem,
	QuestStatus = StateModule.QuestStatus,
}


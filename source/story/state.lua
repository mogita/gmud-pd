-- Story State System
-- Tracks game state: flags, variables, quest progress, and relationships

---@class StoryState
---@field flags table<string, boolean> Boolean flags (e.g., "met_xiaoshutong")
---@field variables table<string, any> Variables (e.g., "gold", "reputation")
---@field quests table<string, table> Quest states (e.g., {status, step, data})
---@field relationships table<string, number> NPC relationship values
local StoryState = {}
StoryState.__index = StoryState

---@alias QuestStatus "unknown"|"available"|"active"|"completed"|"failed"

local QuestStatus = {
	UNKNOWN = "unknown",       -- Not yet discovered
	AVAILABLE = "available",   -- Can be accepted
	ACTIVE = "active",         -- In progress
	COMPLETED = "completed",   -- Successfully finished
	FAILED = "failed",         -- Failed/abandoned
}

---Create a new story state
---@return StoryState
function StoryState.new()
	local self = setmetatable({}, StoryState)
	self.flags = {}
	self.variables = {}
	self.quests = {}
	self.relationships = {}
	return self
end

-- Flag operations

---Set a flag to true
---@param name string Flag name
function StoryState:setFlag(name)
	self.flags[name] = true
end

---Clear a flag (set to false)
---@param name string Flag name
function StoryState:clearFlag(name)
	self.flags[name] = false
end

---Check if a flag is set
---@param name string Flag name
---@return boolean
function StoryState:hasFlag(name)
	return self.flags[name] == true
end

-- Variable operations

---Set a variable value
---@param name string Variable name
---@param value any Variable value
function StoryState:setVar(name, value)
	self.variables[name] = value
end

---Get a variable value
---@param name string Variable name
---@param default any Default value if not set
---@return any
function StoryState:getVar(name, default)
	local value = self.variables[name]
	if value == nil then
		return default
	end
	return value
end

---Increment a numeric variable
---@param name string Variable name
---@param amount number Amount to add (default 1)
function StoryState:incrementVar(name, amount)
	amount = amount or 1
	local current = self:getVar(name, 0)
	self:setVar(name, current + amount)
end

-- Quest operations

---Get quest state
---@param questId string Quest identifier
---@return table quest {status, step, data}
function StoryState:getQuest(questId)
	if not self.quests[questId] then
		self.quests[questId] = {
			status = QuestStatus.UNKNOWN,
			step = 0,
			data = {},
		}
	end
	return self.quests[questId]
end

---Set quest status
---@param questId string Quest identifier
---@param status QuestStatus New status
function StoryState:setQuestStatus(questId, status)
	local quest = self:getQuest(questId)
	quest.status = status
end

---Advance quest to next step
---@param questId string Quest identifier
---@return number newStep The new step number
function StoryState:advanceQuest(questId)
	local quest = self:getQuest(questId)
	quest.step = quest.step + 1
	return quest.step
end

---Check if quest is in a specific status
---@param questId string Quest identifier
---@param status QuestStatus Status to check
---@return boolean
function StoryState:isQuestStatus(questId, status)
	return self:getQuest(questId).status == status
end

-- Relationship operations

---Get relationship value with an NPC
---@param npcId string NPC identifier
---@return number value Relationship value (default 0)
function StoryState:getRelationship(npcId)
	return self.relationships[npcId] or 0
end

---Modify relationship with an NPC
---@param npcId string NPC identifier
---@param delta number Amount to change (positive or negative)
function StoryState:modifyRelationship(npcId, delta)
	local current = self:getRelationship(npcId)
	self.relationships[npcId] = current + delta
end

-- Serialization for save/load

---Export state to a table for saving
---@return table
function StoryState:export()
	return {
		flags = self.flags,
		variables = self.variables,
		quests = self.quests,
		relationships = self.relationships,
	}
end

---Import state from a saved table
---@param data table Saved state data
function StoryState:import(data)
	self.flags = data.flags or {}
	self.variables = data.variables or {}
	self.quests = data.quests or {}
	self.relationships = data.relationships or {}
end

return {
	StoryState = StoryState,
	QuestStatus = QuestStatus,
}


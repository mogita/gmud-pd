-- NPC POI Handlers
-- Handles NPCs with menu-driven interactions

local handlers = import("poi/handlers/init")
local registry = handlers.registry

---@class NPCCapability
---@field TALK string Can have conversations
---@field QUEST string Can give/complete quests
---@field TRADE string Can buy/sell items (merchant)
---@field TRAIN string Can teach skills (trainer)
---@field INFO string Can show NPC information
---@field COMBAT string Can be challenged to combat
local NPCCapability = {
	TALK = "talk",
	QUEST = "quest",
	TRADE = "trade",
	TRAIN = "train",
	INFO = "info",
	COMBAT = "combat",
}

-- Menu labels for each capability (Chinese)
local CapabilityLabels = {
	[NPCCapability.TALK] = "交谈",
	[NPCCapability.QUEST] = "任务",
	[NPCCapability.TRADE] = "交易",
	[NPCCapability.TRAIN] = "学艺",
	[NPCCapability.INFO] = "查看",
	[NPCCapability.COMBAT] = "切磋",
}

---Get available menu options for an NPC
---@param poi POI The NPC POI
---@param player table The player (for condition checks)
---@return table[] options Array of {id, label, enabled}
local function getMenuOptions(poi, player)
	local options = {}
	local npcData = poi.data or {}
	local capabilities = npcData.capabilities or { NPCCapability.TALK, NPCCapability.INFO }

	for _, cap in ipairs(capabilities) do
		local option = {
			id = cap,
			label = CapabilityLabels[cap] or cap,
			enabled = true, -- TODO: Check conditions via story system
		}

		-- Special condition checks
		if cap == NPCCapability.QUEST then
			-- TODO: Check if NPC has available quests for player
			-- option.enabled = QuestSystem:hasAvailableQuests(npcData.npcId, player)
		elseif cap == NPCCapability.TRADE then
			-- TODO: Check if merchant is open/available
			-- option.enabled = npcData.isOpen ~= false
		end

		table.insert(options, option)
	end

	return options
end

-- Sub-handler: Start dialogue with NPC
registry:register("npc_talk", function(player, poi, context)
	print("[NPC] Starting dialogue with: " .. poi.id)

	local npcData = poi.data or {}
	local dialogueId = npcData.dialogueId or poi.id .. "_default"

	-- TODO: Integrate with dialogue system
	-- context.dialogueSystem:start(dialogueId, npcData)

	print("[NPC] Would start dialogue: " .. dialogueId)
end)

-- Sub-handler: Show quest menu
registry:register("npc_quest", function(player, poi, context)
	print("[NPC] Showing quests for: " .. poi.id)

	local npcData = poi.data or {}
	local quests = npcData.quests or {}

	-- TODO: Show quest selection/status UI
	-- context.questUI:showForNPC(npcData.npcId, quests)

	print("[NPC] Available quests: " .. #quests)
end)

-- Sub-handler: Open trade/shop
registry:register("npc_trade", function(player, poi, context)
	print("[NPC] Opening shop for: " .. poi.id)

	local npcData = poi.data or {}

	-- TODO: Open shop UI
	-- context.shopUI:open(npcData.inventory, npcData.prices)
end)

-- Sub-handler: Open training menu
registry:register("npc_train", function(player, poi, context)
	print("[NPC] Opening training for: " .. poi.id)

	local npcData = poi.data or {}
	local skills = npcData.teachableSkills or {}

	-- TODO: Open training UI
	-- context.trainingUI:open(skills, npcData.requirements)

	print("[NPC] Teachable skills: " .. #skills)
end)

-- Sub-handler: Show NPC info
registry:register("npc_info", function(player, poi, context)
	print("[NPC] Showing info for: " .. poi.id)

	local npcData = poi.data or {}

	-- TODO: Show NPC info panel
	-- context.infoUI:showNPC(npcData)
end)

-- Sub-handler: Start combat
registry:register("npc_combat", function(player, poi, context)
	print("[NPC] Starting combat with: " .. poi.id)

	local npcData = poi.data or {}

	-- TODO: Transition to combat system
	-- context.combatSystem:start(player, npcData)
end)

-- Default handler for NPC category
-- Shows menu with available options
registry:registerCategoryDefault("npc", function(player, poi, context)
	print("[NPC] Interacting with: " .. poi.id)

	local options = getMenuOptions(poi, player)

	-- TODO: Show NPC menu UI and handle selection
	-- For now, just log options
	print("[NPC] Menu options:")
	for i, opt in ipairs(options) do
		print("  " .. i .. ". " .. opt.label .. (opt.enabled and "" or " (disabled)"))
	end

	-- Temporary: auto-trigger talk if available
	if #options > 0 and options[1].id == NPCCapability.TALK then
		registry:get("npc_talk")(player, poi, context)
	end
end)

return {
	NPCCapability = NPCCapability,
	CapabilityLabels = CapabilityLabels,
	getMenuOptions = getMenuOptions,
}


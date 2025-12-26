-- NPC Data: 小书童 (Little Scholar's Attendant)
-- A young servant at the martial arts school

return {
	id = "xiaoshutong",
	name = "小书童",
	title = "武馆杂役",

	-- Base stats (for combat/training)
	stats = {
		level = 1,
		hp = 50,
		mp = 20,
	},

	-- Capabilities this NPC offers
	capabilities = { "talk", "quest", "trade" },

	-- Dialogue configuration
	dialogue = {
		-- Default greeting (changes based on story state)
		greeting = {
			default = "xiaoshutong_greeting_default",
			-- Conditional greetings based on story flags
			conditions = {
				{ flag = "quest_fetch_brush_complete", dialogueId = "xiaoshutong_greeting_after_quest" },
				{ flag = "met_xiaoshutong", dialogueId = "xiaoshutong_greeting_return" },
			},
		},
	},

	-- Quests this NPC can give
	quests = {
		{
			id = "fetch_brush",
			name = "寻找毛笔",
			-- Conditions to show this quest
			available = {
				{ type = "hasFlag", params = { flag = "met_xiaoshutong" } },
				{ type = "questStatus", params = { quest = "fetch_brush", status = "unknown" } },
			},
		},
	},

	-- Items for trade (if merchant)
	inventory = {
		{ itemId = "ink_stick", price = 10, stock = 5 },
		{ itemId = "paper_bundle", price = 5, stock = 10 },
	},

	-- Relationship thresholds for special interactions
	relationshipThresholds = {
		friendly = 20,   -- Unlocks friendly dialogue
		trusted = 50,    -- Unlocks special quests
		ally = 100,      -- Unlocks combat assistance
	},
}


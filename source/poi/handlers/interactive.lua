-- Interactive POI Handlers
-- Handles wells, signs, bulletin boards, and other interactable objects

-- Setup function called by init.lua with the registry
return function(registry)
	-- Handler: Drink from well (original message from gmud circa 2000)
	registry:register("drink_water", function(player, poi, context)
		print("[Interactive] Drinking from well: " .. poi.id)
		-- TODO: Implement thirst system
		-- player:modifyStat("thirst", poi.data.thirstRestore or 20)

		-- Show feedback message
		if context.showMessage then
			context.showMessage("你在井边用杯子舀起井水喝了几口")
		end
	end)

	-- Handler: Read a sign or boundary stone
	registry:register("read_sign", function(player, poi, context)
		print("[Interactive] Reading sign: " .. poi.id)

		local text = poi.data.text or "（字迹模糊，无法辨认）"

		if context.showMessage then
			context.showMessage(text)
		end
	end)

	-- Handler: View bulletin board
	registry:register("view_board", function(player, poi, context)
		print("[Interactive] Viewing board: " .. poi.id)

		-- TODO: Integrate with quest system
		-- local quests = QuestSystem:getAvailableQuests(poi.data.boardId)

		if context.showMessage then
			context.showMessage(poi.data.text or "告示板上空无一物")
		end
	end)

	-- Default handler for interactive category (fallback when no handlerName specified)
	registry:registerCategoryDefault("interactive", function(player, poi, context)
		print("[Interactive] No handler for POI: " .. poi.id)
	end)
end

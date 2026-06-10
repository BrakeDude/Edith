---CHALLENGE UNLOCKS-------------------------------------------------
local Helpers = EdithRestored.Helpers
local marksA = EdithRestored.Enums.Achievements.Unlocks.ASide
local marksB = EdithRestored.Enums.Achievements.Unlocks.BSide
local pgd = EdithRestored.PGD

EdithRestored:AddCallback(ModCallbacks.MC_PRE_RENDER_CUSTOM_CHARACTER_MENU, function(_, id, pos, sprite)
	if id == EdithRestored.Enums.PlayerType.EDITH then
		local sprite = EntityConfig.GetPlayer(id):GetModdedMenuBackgroundSprite()
		local layerIcon = sprite:GetLayer(7)
		local layerName = sprite:GetLayer(8)
		if not pgd:Unlocked(EdithRestored.Enums.Achievements.CompletionMarks.SALT_SHAKER) then
			layerIcon:SetSize(Vector.Zero)
			layerName:SetSize(Vector.Zero)
		else
			layerIcon:SetSize(Vector.One)
			layerName:SetSize(Vector.One)
		end
	end
end)

local function UnlockEdith(doUnlock, ach, force)
	if doUnlock then
		if
			EdithRestored.Enums.Achievements.Unlocks.Characters[ach]
			and EdithRestored.Enums.Achievements.Unlocks.Characters[ach].Condition()
		then
			Helpers.UnlockAchievement(ach, force)
		end
	end
end

EdithRestored:AddCallback(ModCallbacks.MC_POST_SAVESLOT_LOAD, function(_, slot, selected, raw)
	UnlockEdith(selected, EdithRestored.Enums.Achievements.Characters.EDITH, true)
	--UnlockEdith(selected, EdithRestored.Enums.Achievements.Characters.EDITH_B, true)
	for ach, data in pairs(EdithRestored.Enums.Achievements.Unlocks.Misc) do
		if data.Condition() then
			Helpers.UnlockAchievement(ach)
		end
	end
end)

EdithRestored:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, load)
	UnlockEdith(true, EdithRestored.Enums.Achievements.Characters.EDITH, true)
	--UnlockEdith(true, EdithRestored.Enums.Achievements.Characters.EDITH_B, true)
	for ach, data in pairs(EdithRestored.Enums.Achievements.Unlocks.Misc) do
		if data.Condition() then
			Helpers.UnlockAchievement(ach)
		end
	end
end)

for challenge, achievement in pairs(EdithRestored.Enums.Challenges) do
	EdithRestored:AddCallback(ModCallbacks.MC_POST_CHALLENGE_DONE, function(_, id)
		Helpers.UnlockAchievement(achievement)
	end, achievement)
end

EdithRestored:AddCallback(ModCallbacks.MC_POST_COMPLETION_EVENT, function(_, mark)
	if PlayerManager.AnyoneIsPlayerType(EdithRestored.Enums.PlayerType.EDITH) then
		for ach_mark, data in pairs(marksA) do
			if data.Condition() then
				Helpers.UnlockAchievement(ach_mark)
			end
		end
	end
	--[[if PlayerManager.AnyoneIsPlayerType(EdithRestored.Enums.PlayerType.EDITH_B) then
		for ach_mark, data in pairs(marksB) do
			if data.Condition() then
				Helpers.UnlockAchievement(ach_mark)
			end
		end
	end]]
	if mark == CompletionType.BEAST then
		Helpers.UnlockAchievement(EdithRestored.Enums.Achievements.Characters.EDITH)
	end
	for ach, data in pairs(EdithRestored.Enums.Achievements.Unlocks.Misc) do
		if data.Condition() then
			Helpers.UnlockAchievement(ach)
		end
	end
end)

--[[EdithRestored:AddCallback(ModCallbacks.MC_POST_SLOT_UPDATE, function(_, slot)
	if
		slot.SubType == EdithRestored.Enums.PlayerType.EDITH_B
		and slot:GetSprite():IsEventTriggered("Poof")
		and EdithRestored.Level():GetCurrentRoomIndex() == 94
		and EdithRestored.Level():GetStage() == LevelStage.STAGE8
		and not pgd:Unlocked(EdithRestored.Enums.Achievements.Characters.TAINTED)
	then
		Helpers.UnlockAchievement(EdithRestored.Enums.Achievements.Characters.TAINTED)
	end
end, SlotVariant.HOME_CLOSET_PLAYER)]]

EdithRestored:AddCallback(ModCallbacks.MC_GET_CARD, function(_, rng, card, playing, runes, onlyrunes)
	if
		card == EdithRestored.Enums.Pickups.Cards.CARD_SOUL_EDITH
			and not pgd:Unlocked(EdithRestored.Enums.Achievements.CompletionMarks.SOUL_EDITH)
		--[[or card == EdithRestored.Enums.Pickups.Cards.CARD_PRUDENCE and not pgd:Unlocked(
			EdithRestored.Enums.Achievements.CompletionMarks.PRUDENCE
		)
		or card == EdithRestored.Enums.Pickups.Cards.CARD_REVERSE_PRUDENCE
			and not pgd:Unlocked(EdithRestored.Enums.Achievements.CompletionMarks.REV_PRUDENCE)]]
	then
		return 0
	end
end)

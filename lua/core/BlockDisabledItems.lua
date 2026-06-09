local BlockDisabledItems = {}
local Helpers = EdithRestored.Helpers

local itemPool = EdithRestored.Game:GetItemPool()
local itemConfig = Isaac.GetItemConfig()

local lookupTables = {
    ["DisabledItems"] = {Table = EdithRestored.Enums.CollectibleType, Config = itemConfig.GetCollectible},
    ["DisabledTrinkets"] = {Table = EdithRestored.Enums.TrinketType, Config = itemConfig.GetTrinket},
}

function BlockDisabledItems:OnGameStart(isContinue)
    local trinketsNotInPool = {}
	local trinketsSize = Helpers.GetMaxTrinketID()
	for i = 1, trinketsSize do
        local trinketConf = itemConfig:GetTrinket(i)
        if trinketConf and trinketConf:IsTrinket() then
            if not itemPool:HasTrinket(i) then
                trinketsNotInPool[i] = true
            end
        end
	end
	itemPool:ResetTrinkets()
    for disableTable, lookup in pairs(lookupTables) do
        for index, item in pairs(lookup.Table) do
            local itemConf = lookup.Config(itemConfig, item)
            if itemConf then
                itemConf.Hidden = false
            end
        end
        for index, disabled in pairs(EdithRestored:GetDefaultFileSave(disableTable)) do
            if lookup.Table[index] then
                local itemConf = lookup.Config(itemConfig, lookup.Table[index])
                itemConf.Hidden = true
                if itemConf:IsTrinket() then
                    trinketsNotInPool[lookup.Table[index]] = true
                end
            end
        end
    end
    for id, notInPool in pairs(trinketsNotInPool) do
		itemPool:RemoveTrinket(id)
	end
end
EdithRestored:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, BlockDisabledItems.OnGameStart)

local isDisablingItem = false

function BlockDisabledItems:PostGetCollectible(selectedItem, poolType, decrease, seed)
    if isDisablingItem then return end

    local isDisabledItem = false

    for indexItem, disabledItem in pairs(EdithRestored:GetDefaultFileSave("DisabledItems")) do
        if selectedItem == EdithRestored.Enums.CollectibleType[indexItem] then
            isDisabledItem = true
            break
        end
    end

    if not isDisabledItem then return end

    local rng = RNG(seed, 35)

    isDisablingItem = true
    local newItem = itemPool:GetCollectible(poolType, decrease, rng:Next() * 1000)
    isDisablingItem = false

    return newItem
end
EdithRestored:AddCallback(ModCallbacks.MC_POST_GET_COLLECTIBLE, BlockDisabledItems.PostGetCollectible)
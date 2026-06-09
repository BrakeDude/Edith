local RocketLases = {}
local Helpers = EdithRestored.Helpers

---@param bomb EntityBomb
function RocketLases:InstaBoom(bomb)
    if bomb.IsFetus and Helpers.GetPlayerFromTear(bomb) ~= nil and Helpers.IsChallenge(EdithRestored.Enums.Challenges.ROCKET_LACES) then
        bomb:SetExplosionCountdown(0)
    end
end
EdithRestored:AddCallback(ModCallbacks.MC_POST_BOMB_UPDATE, RocketLases.InstaBoom)

---@param player EntityPlayer
---@param cache CacheFlag | integer
function RocketLases:StaticFireRate(player, cache)
    if Helpers.IsChallenge(EdithRestored.Enums.Challenges.ROCKET_LACES) then
        if cache == CacheFlag.CACHE_FIREDELAY then
            player.MaxFireDelay = Helpers.ToMaxFireDelay(0.2)
        end
    end
end
EdithRestored:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, RocketLases.StaticFireRate)

function RocketLases:NoOverrides()
    if Helpers.IsChallenge(EdithRestored.Enums.Challenges.ROCKET_LACES) then
        local pools = EdithRestored.Game:GetItemPool()
        pools:RemoveCollectible(CollectibleType.COLLECTIBLE_EPIC_FETUS)
        pools:RemoveCollectible(CollectibleType.COLLECTIBLE_HAEMOLACRIA)
        pools:RemoveCollectible(CollectibleType.COLLECTIBLE_MOMS_KNIFE)
        pools:RemoveCollectible(CollectibleType.COLLECTIBLE_SPIRIT_SWORD)
        pools:RemoveCollectible(CollectibleType.COLLECTIBLE_ZODIAC)
        pools:RemoveCollectible(CollectibleType.COLLECTIBLE_LIBRA)
    end
end
EdithRestored:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, RocketLases.NoOverrides)
EdithRestored:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, RocketLases.NoOverrides)
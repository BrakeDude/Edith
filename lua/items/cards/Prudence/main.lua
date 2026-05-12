local Cards = {}

---@param prud Card | integer
---@param player EntityPlayer
---@param useflags UseFlag | integer
function Cards:UsePrudence(prud, player, useflags)
    player:SetInnateCollectibleCount(CollectibleType.COLLECTIBLE_GUPPYS_EYE, 1, "EDITH_PRUDENCE_SEEING", false)
end
EdithRestored:AddCallback(ModCallbacks.MC_USE_CARD, Cards.UsePrudence, EdithRestored.Enums.Pickups.Cards.CARD_PRUDENCE)

function Cards:NewRoom()
    for _, player in ipairs(PlayerManager.GetPlayers()) do
        player:ClearInnateItemGroup("EDITH_PRUDENCE_SEEING")
    end
end
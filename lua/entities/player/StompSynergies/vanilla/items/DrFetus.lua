local DrFetus = {}
local game = EdithRestored.Game

---@param player EntityPlayer
---@param stompDamage number
---@param bombLanding boolean
---@param forced boolean
---@param isStompPool table
function DrFetus:OnStomp(player, stompDamage, bombLanding, forced, isStompPool)
    if bombLanding then return end
    game:BombExplosionEffects(player.Position, player.Damage * 5, player.TearFlags, Color.Default, player, 1, true, false)
end
EdithRestored:AddCallback(
	EdithRestored.Enums.Callbacks.ON_EDITH_STOMP,
	DrFetus.OnStomp,
	{ Item = CollectibleType.COLLECTIBLE_DR_FETUS }
)

return DrFetus
local JacobsLadder = {}
local game = EdithRestored.Game

---@param player EntityPlayer
---@param stompDamage number
---@param bombLanding boolean
---@param forced boolean
---@param isStompPool table
function JacobsLadder:OnStomp(player, stompDamage, bombLanding, forced, isStompPool)
	game:ChainLightning(player.Position, player.Damage, player.TearFlags, player)
end
EdithRestored:AddCallback(
	EdithRestored.Enums.Callbacks.ON_EDITH_STOMP,
	JacobsLadder.OnStomp,
	{ Item = CollectibleType.COLLECTIBLE_JACOBS_LADDER, PoolFruitCake = true }
)

return JacobsLadder
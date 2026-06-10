local FireMind = {}
local Helpers = EdithRestored.Helpers
local game = EdithRestored.Game

---@param player EntityPlayer
---@param stompDamage number
---@param bombLanding boolean
---@param forced boolean
---@param isStompPool table
function FireMind:OnStomp(player, stompDamage, bombLanding, forced, isStompPool)
	local rng = player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_FIRE_MIND)
	local chance = 1 / (10 - (Helpers.Clamp(player.Luck, 0, 13) * 0.7))
	for _, enemy in ipairs(Helpers.GetEnemiesInRadius(player.Position, Helpers.GetStompRadius())) do
		enemy:AddBurn(EntityRef(player), 40, player.Damage)
	end
	if rng:RandomFloat() <= chance or isStompPool.Pool3DollarBill or isStompPool.PoolFruitCake or isStompPool.PoolPlaydoughCookie then
		game:BombExplosionEffects(player.Position, player.Damage, TearFlags.TEAR_BURN, Color.Default, player)
	end
end
EdithRestored:AddCallback(
	EdithRestored.Enums.Callbacks.ON_EDITH_STOMP,
	FireMind.OnStomp,
	{ Item = CollectibleType.COLLECTIBLE_FIRE_MIND, Pool3DollarBill = true, PoolFruitCake = true, PoolPlaydoughCookie = true }
)

return FireMind
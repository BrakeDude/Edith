local SlippysGuts = {}
local sfx = EdithRestored.SFX

---@param player EntityPlayer
---@param bombDamage number
---@param position Vector
---@param radius number
---@param hasBombs boolean
---@param isGigaBomb boolean
---@param isScatterBomb boolean
---@return table?
function SlippysGuts:OnStompExplosion(player, bombDamage, position, radius, hasBombs, isGigaBomb, isScatterBomb)
	local cloud = Isaac.Spawn(
		FiendFolio.FF.SlippyFart.ID,
		FiendFolio.FF.SlippyFart.Var,
		FiendFolio.FF.SlippyFart.Sub,
		position,
		Vector.Zero,
		player
	)
	sfx:Play(FiendFolio.Sounds.FartFrog1, 0.2, 0, false, math.random(80, 120) / 100)

	if isScatterBomb then
		cloud:GetData().RadiusMult = 0.5
		cloud.SpriteScale = Vector(0.5, 0.5)
	end
end
EdithRestored:AddCallback(
	EdithRestored.Enums.Callbacks.ON_EDITH_STOMP_EXPLOSION,
	SlippysGuts.OnStompExplosion,
	{Item = FiendFolio.ITEM.COLLECTIBLE.SLIPPYS_GUTS }
)

return SlippysGuts

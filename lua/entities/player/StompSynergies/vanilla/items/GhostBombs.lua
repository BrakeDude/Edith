local GhostBombs = {}
local sfx = EdithRestored.SFX

---@param player EntityPlayer
---@param bombDamage number
---@param position Vector
---@param radius number
---@param hasBombs boolean
---@param isGigaBomb boolean
---@param isScatterBomb boolean
---@return table?
function GhostBombs:OnStompExplosion(player, bombDamage, position, radius, hasBombs, isGigaBomb, isScatterBomb)
	local ghost =
		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HUNGRY_SOUL, 1, player.Position, Vector.Zero, player)
			:ToEffect()
	ghost:SetTimeout(300)
	sfx:Play(SoundEffect.SOUND_FLOATY_BABY_ROAR, 1, 0, false, 1.75, 0)
end
EdithRestored:AddCallback(
	EdithRestored.Enums.Callbacks.ON_EDITH_STOMP_EXPLOSION,
	GhostBombs.OnStompExplosion,
	{ Item = CollectibleType.COLLECTIBLE_GHOST_BOMBS }
)

return GhostBombs

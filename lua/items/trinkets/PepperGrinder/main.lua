local PepperGrinder = {}

function PepperGrinder:OnKillPG(entity)
	local num = PlayerManager.GetTotalTrinketMultiplier(EdithRestored.Enums.TrinketType.TRINKET_PEPPER_GRINDER)
	if num == 0 then return end

	local rng = RNG(entity.DropSeed)
	local roll = rng:RandomFloat()

	if (num <= 2 or roll > 0.75)
	and (num <= 1 or num >= 3 or roll > 0.5)
	and (num >= 2 or roll > 0.25) then
		return
	end

	EdithRestored.Game:SpawnParticles(entity.Position, EffectVariant.POOF02, 1, 0, Color(0, 0, 0, 1, 0.25, 0.25, 0.25), 1, 0)

	for i = 1, 5 do
		local creep = TSIL.EntitySpecific.SpawnEffect(
			53,
			0,
			entity.Position,
			rng:RandomVector() * 2
		)
		local sprite = creep:GetSprite()

		creep.CollisionDamage = 0.4

		sprite:Load("gfx/1000.092_creep (powder).anm2", true)
		sprite:ReplaceSpritesheet(0, "gfx/effects/effect_blackpowder.png")
		sprite:Play("SmallBlood0" .. rng:RandomInt(1, 6), true)
	end
end
EdithRestored:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, PepperGrinder.OnKillPG)
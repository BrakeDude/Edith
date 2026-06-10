local BlastBoots = {}
local sfx = EdithRestored.SFX
local timerColor = Color(1, 1, 1, 1, 0.5)
local BlastBootsID = EdithRestored.Enums.CollectibleType.COLLECTIBLE_BLASTING_BOOTS
local Helpers = EdithRestored.Helpers

local BootsJumpInfo = {
	Height = 13,
	Speed = 1,
	Flags = JumpLib.Flags.NO_HURT_PITFALL
		| JumpLib.Flags.FAMILIAR_FOLLOW_ORBITALS
		| JumpLib.Flags.FAMILIAR_FOLLOW_TEARCOPYING,
	Tags = { "BlastingBootsJump" },
}

local function IsEdithExtraAnim(player)
	local s = player:GetSprite():GetAnimation()
	return s:sub(1, 5) == "Edith"
end

---@param player EntityPlayer
---@param flags DamageFlag | integer
function BlastBoots:PreBombDamage(player, _, flags)
	if flags & DamageFlag.DAMAGE_EXPLOSION == 0 or not player:HasCollectible(BlastBootsID) then
		return
	end
	local data = EdithRestored:GetData(player)
	if data.AfterPitfall == nil
	and not (IsEdithExtraAnim(player)
	or data.Statue) then
		JumpLib:Jump(player, BootsJumpInfo)
	end
	return false
end
EdithRestored:AddCallback(ModCallbacks.MC_PRE_PLAYER_TAKE_DMG, BlastBoots.PreBombDamage)

function BlastBoots:BlastingBootsExtraJump(player, bombDamage, position, radius, hasBombs, isGigaBomb, isScatterBomb)
	JumpLib:Jump(player, BootsJumpInfo)
end
EdithRestored:AddCallback(
	EdithRestored.Enums.Callbacks.ON_EDITH_STOMP_EXPLOSION,
	BlastBoots.BlastingBootsExtraJump,
	{ Item = BlastBootsID }
)

local function GetCooldown()
	return EdithRestored.DebugMode and EdithRestored:GetDebugValue("BlastingBootsCd") or 150
end

---@param player EntityPlayer
function BlastBoots:AntiSoftlock(player)
	if not player:HasCollectible(BlastBootsID) then
		return
	end
	local playerData = EdithRestored:GetData(player)
	local movDir = player:GetMovementDirection()

	if EdithRestored.DebugMode and EdithRestored:GetDebugValue("BlastingBootsDisable") then
		playerData.Antisoftlocktimer = nil
		return
	end

	playerData.Antisoftlocktimer = playerData.Antisoftlocktimer or GetCooldown()

	if
		not (
			movDir == Direction.NO_DIRECTION
			and not JumpLib:GetData(player).Jumping
			and not playerData.EdithTargetMovementPosition
		)
	then
		playerData.Antisoftlocktimer = GetCooldown()
		return
	end

	playerData.Antisoftlocktimer = math.max(playerData.Antisoftlocktimer - 1, 0)
	local timer = playerData.Antisoftlocktimer

	if timer <= 30 and timer > 0 and timer % 10 == 0 then
		sfx:Play(SoundEffect.SOUND_BEEP, 1)
		player:SetColor(timerColor, 8, 1, true, false)
	end

	if timer ~= 0 then
		return
	end
	playerData.Antisoftlocktimer = GetCooldown()
	JumpLib:Jump(player, BootsJumpInfo)

	---@diagnostic disable-next-line: param-type-mismatch
	local explosion =
		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BOMB_EXPLOSION, 0, player.Position, Vector.Zero, nil)
			:ToEffect()
	explosion.SpriteScale = Vector.One:Resized(player.Size) / 20
end
EdithRestored:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, BlastBoots.AntiSoftlock)

---@param player EntityPlayer
---@param jumpData JumpData
---@param inPit boolean
function BlastBoots:Landing(player, jumpData, inPit)
	local data = EdithRestored:GetData(player)
	if not inPit and data.AfterPitfall == nil then
		local mult = Helpers.IsChallenge(EdithRestored.Enums.Challenges.ROCKET_LACES) and 3 or 1.5
		Helpers.Stomp(player, mult, false, false)
		player:ResetDamageCooldown()
		player:SetMinDamageCooldown(60)
		for _, v in pairs(Isaac.FindInRadius(player.Position, 55, EntityPartition.BULLET)) do
			local projectile = v:ToProjectile() ---@cast projectile EntityProjectile
			local angle = ((player.Position - projectile.Position) * -1):GetAngleDegrees()
			projectile.Velocity = Vector.FromAngle(angle):Resized(10)
			projectile:AddProjectileFlags(ProjectileFlags.CANT_HIT_PLAYER)
			projectile:AddProjectileFlags(ProjectileFlags.HIT_ENEMIES)
		end
	else
		data.HTJ = nil
		data.AfterPitfall = false
	end
end
EdithRestored:AddCallback(
	JumpLib.Callbacks.ENTITY_LAND,
	BlastBoots.Landing,
	{ tag = "BlastingBootsJump", type = EntityType.ENTITY_PLAYER }
)

---@param player EntityPlayer
---@param jumpData JumpData
function BlastBoots:EdithMidAir(player, jumpData)
	if Helpers.CantMove(player) and player.ControlsEnabled and not player:IsDead() and not player:IsCoopGhost() then
		local vec = Helpers.GetMovementActionVector(player)
		if vec:Length() > 0 then
			player.Velocity = Helpers.Lerp(player.Velocity, vec:Resized(8 * player.MoveSpeed), 0.08)
		end
	end
end
EdithRestored:AddCallback(
	JumpLib.Callbacks.ENTITY_UPDATE_30,
	BlastBoots.EdithMidAir,
	{ tag = "BlastingBootsJump", type = EntityType.ENTITY_PLAYER, player = EdithRestored.Enums.PlayerType.EDITH }
)

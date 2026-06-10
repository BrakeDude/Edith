local Peppermint = {}
local Helpers = EdithRestored.Helpers

-- Hi here Kotry, here's Peppermint rework, right now its main functionality is done
-- Code formatted with https://codebeautify.org/lua-beautifier

--[[
	Known issues
	- Actually i haven't found any major issue, just lack of visual effect but i think it would be better if a spriter makes it so yeah, it's pretty much done
	- Ah yeah we need sound effect too
]]

-- Conversions between directions to vectors.
local DIRECTION_TO_VECTOR = {
	[Direction.NO_DIRECTION] = Vector(0, 0),
	[Direction.RIGHT] = Vector(1, 0),
	[Direction.DOWN] = Vector(0, 1),
	[Direction.LEFT] = Vector(-1, 0),
	[Direction.UP] = Vector(0, -1),
}

local maxCharge = 210

---@return integer
local function GetMaxCharge()
	return EdithRestored.DebugMode and EdithRestored:GetDebugValue("PeppermintCharge") or maxCharge
end

---@param cloud EntityEffect
---@return Capsule
local function GetCollisionCapsule(cloud)
	if EdithRestored.DebugMode then
		local offset = Vector(EdithRestored:GetDebugValue("PeppermintCloudPosOffsetX"), EdithRestored:GetDebugValue("PeppermintCloudPosOffsetY"))
		local mult = Vector(EdithRestored:GetDebugValue("PeppermintCloudSizeXMult"), EdithRestored:GetDebugValue("PeppermintCloudSizeYMult"))
		return Capsule(cloud.Position + offset, mult, 0,  EdithRestored:GetDebugValue("PeppermintCloudSize"))
	else
		return cloud:GetCollisionCapsule(Vector(0, -25))
	end
end

-- Returns a vector representing the direction the player is aiming at.
---@param player EntityPlayer
---@return Vector
local function getAimDirection(player)
	if
		player:HasCollectible(CollectibleType.COLLECTIBLE_MARKED)
		or player:HasCollectible(CollectibleType.COLLECTIBLE_ANALOG_STICK)
		or player:HasCollectible(CollectibleType.COLLECTIBLE_EYE_OF_THE_OCCULT)
		or player:HasCollectible(CollectibleType.COLLECTIBLE_EPIC_FETUS)
		or player:HasCollectible(CollectibleType.COLLECTIBLE_LUDOVICO_TECHNIQUE)
	then
		return player:GetAimDirection()
	end

	return DIRECTION_TO_VECTOR[player:GetHeadDirection()]
end

function Peppermint:RenderPepperMintCharge(player)
	local data = EdithRestored:GetData(player)
	local room = EdithRestored.Room()

	if room:GetRenderMode() == RenderMode.RENDER_WATER_REFLECT then
		return
	end

	if not player:HasCollectible(EdithRestored.Enums.CollectibleType.COLLECTIBLE_PEPPERMINT) then
		return
	end

	if not data.PeppermintChargeBar then
		data.PeppermintChargeBar = Sprite("gfx/ui/chargebarpeppermint.anm2", true)
	end
	data.PeppermintChargeBar.Offset = Vector(-18 * player.SpriteScale.X, -20 * player.SpriteScale.Y)
	HudHelper.RenderChargeBar(
		data.PeppermintChargeBar,
		math.max(0, data.PeppermintCharge or 0),
		GetMaxCharge(),
		EdithRestored.Room():WorldToScreenPosition(player.Position)
	)
end
EdithRestored:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, Peppermint.RenderPepperMintCharge, 0)

---@param player EntityPlayer
function Peppermint:AddPeppermintCharge(player)
	local data = EdithRestored:GetData(player)

	if not player:HasCollectible(EdithRestored.Enums.CollectibleType.COLLECTIBLE_PEPPERMINT) then
		return
	end

	if not data.PeppermintCharge then
		data.PeppermintCharge = 0
	end

	local shoot = {
		l = Input.IsActionPressed(ButtonAction.ACTION_SHOOTLEFT, player.ControllerIndex),
		r = Input.IsActionPressed(ButtonAction.ACTION_SHOOTRIGHT, player.ControllerIndex),
		u = Input.IsActionPressed(ButtonAction.ACTION_SHOOTUP, player.ControllerIndex),
		d = Input.IsActionPressed(ButtonAction.ACTION_SHOOTDOWN, player.ControllerIndex),
	}

	local isShooting = (shoot.l or shoot.r or shoot.u or shoot.d)

	if isShooting == true then
		data.PeppermintCharge = math.min(GetMaxCharge(), data.PeppermintCharge + 1)
		data.LastAimDirection = getAimDirection(player)
	else
		if data.PeppermintCharge >= GetMaxCharge() then
			local lastAimDir = data.LastAimDirection or getAimDirection(player)
			local speed = lastAimDir:Resized(4)
			local pepperMintBreath = Isaac.Spawn(
				EntityType.ENTITY_EFFECT,
				EdithRestored.Enums.Entities.PEPPERMINT.Variant,
				0,
				player.Position + lastAimDir:Resized(20),
				speed,
				player
			):ToEffect()
			pepperMintBreath.PositionOffset = Vector(0, -25)
			pepperMintBreath:GetSprite():Play("Appear", true)
			pepperMintBreath.CollisionDamage = player.Damage / 4
			pepperMintBreath:SetTimeout(600)
			EdithRestored.SFX:Play(EdithRestored.Enums.SFX.PEPPERMINT_BREATH, 0.8, 0, false, 1.0)
		end
		data.PeppermintCharge = 0
		data.LastAimDirection = nil
	end
end
EdithRestored:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, Peppermint.AddPeppermintCharge)

local slowColor = Color(0.7, 0.9, 1, 1, 0, 0, 0)

---@param cloud EntityEffect
function Peppermint:CloudUpdate(cloud)
	local sprite = cloud:GetSprite()
	if sprite:IsFinished("Appear") then	
		sprite:Play("Idle", true)
	end
	if sprite:IsFinished("Disappear") then
		cloud:Remove()
		return
	end
	if cloud.Timeout <= 0 and not sprite:IsPlaying("Disappear") then
		sprite:Play("Disappear", true)
	end

	if sprite:IsPlaying("Disappear") then
		return
	end
	if cloud:CollidesWithGrid() and cloud.Timeout > 15 then
		cloud:SetTimeout(15)
	end
	
	cloud.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
	--cloud.Position = player.Position + getAimDirection(player):Resized(20)
	local data = EdithRestored:GetData(cloud)
	local capsule = GetCollisionCapsule(cloud)
	data.Pushed = data.Pushed or {}
	for _, obj in ipairs(Isaac.FindInCapsule(capsule, EntityPartition.TEAR)) do
		if not data.Pushed[GetPtrHash(obj)] then
			data.Pushed[GetPtrHash(obj)] = true
			cloud.Velocity = cloud.Velocity + obj.Velocity:Resized(0.5)
		end
	end
	cloud.Velocity = Helpers.Lerp(cloud.Velocity, cloud.Velocity:Resized(0.5), 0.3, 0.2)
	if cloud.Timeout > 10 then
		for _, enemy in ipairs(Isaac.FindInCapsule(capsule, EntityPartition.ENEMY)) do
			-- Make sure it can be hurt.
			if enemy:IsVulnerableEnemy() and enemy:IsActiveEnemy() then
				if enemy:GetDamageCountdown() == 0 then
					enemy:TakeDamage(EdithRestored.DebugMode and EdithRestored:GetDebugValue("PeppermintCloudDamage") or cloud.CollisionDamage, DamageFlag.DAMAGE_COUNTDOWN, EntityRef(cloud), 10)
					if enemy:GetSlowingCountdown() < 60 then
						enemy:AddSlowing(EntityRef(cloud), 60, 0.5, slowColor)
						enemy:SetSlowingCountdown(60)
						enemy:SetColor(slowColor, 60, 0, true, false)
					else
						enemy:AddSlowing(EntityRef(cloud), 20, 0.5, slowColor)
						enemy:SetColor(slowColor, enemy:GetSlowingCountdown() + 20, 0, true, false)
					end
					if enemy:GetIceCountdown() < 60 then
						enemy:AddIce(EntityRef(cloud), 60)
						enemy:SetIceCountdown(60)
					else
						enemy:AddIce(EntityRef(cloud), 20)
					end
				end
			end
		end
	end
end
EdithRestored:AddCallback(
	ModCallbacks.MC_POST_EFFECT_UPDATE,
	Peppermint.CloudUpdate,
	EdithRestored.Enums.Entities.PEPPERMINT.Variant
)

---@param cloud EntityEffect
EdithRestored:AddCallback(ModCallbacks.MC_POST_EFFECT_RENDER, function(_, cloud)
	cloud:GetSprite().Offset = Vector(0, 20)
	cloud.DepthOffset = 3
	if EdithRestored.DebugMode then
		local shape = cloud:GetDebugShape(true)
		local capsule = GetCollisionCapsule(cloud)
		shape:Capsule(capsule)
	end
end, EdithRestored.Enums.Entities.PEPPERMINT.Variant)

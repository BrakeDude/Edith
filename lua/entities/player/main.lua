local Helpers = EdithRestored.Helpers
local sfx = EdithRestored.SFX
local game = EdithRestored.Game
local level = EdithRestored.Level

local SlideColors = {
	Water = {
		[BackdropType.CORPSE3] = Color(1, 0.2, 0.2),
		[BackdropType.DROSS] = Color(92 / 255, 81 / 255, 71 / 255),
		Default = Color(0.7, 0.75, 1),
	},
	Flesh = {
		[BackdropType.BLUE_WOMB] = Color(0, 0, 0, 1, 0.3, 0.4, 0.6),
		[BackdropType.CORPSE] = Color(0, 0, 0, 1, 0.62, 0.65, 0.62),
		[BackdropType.CORPSE2] = Color(0, 0, 0, 1, 0.55, 0.57, 0.55),
		Default = Color.Default
	}
}

local HoodColorList = {
	[SkinColor.SKIN_WHITE] = "",
	[SkinColor.SKIN_BLACK] = "_black",
	[SkinColor.SKIN_BLUE] = "_blue",
	[SkinColor.SKIN_RED] = "_red",
	[SkinColor.SKIN_GREEN] = "_green",
	[SkinColor.SKIN_GREY] = "_grey",
}

local Chap4Backdrops = {
	[BackdropType.WOMB] = true,
	[BackdropType.UTERO] = true,
	[BackdropType.SCARRED_WOMB] = true,
	[BackdropType.BLUE_WOMB] = true,
	[BackdropType.CORPSE] = true,
	[BackdropType.CORPSE2] = true,
	[BackdropType.CORPSE3] = true,
	[BackdropType.MORTIS] = true, --- Who knows
}

local function IsChap4()
	local backdrop = EdithRestored.Room():GetBackdropType()
	return Chap4Backdrops[backdrop] or false 
end

if CustomHealthAPI then
	CustomHealthAPI.PersistentData.CharactersThatCantHaveRedHealth[EdithRestored.Enums.PlayerType.EDITH] = true
	CustomHealthAPI.PersistentData.CharactersThatCantHaveRedHealth[EdithRestored.Enums.PlayerType.EDITH_B] = true
	CustomHealthAPI.PersistentData.CharactersThatConvertMaxHealth[EdithRestored.Enums.PlayerType.EDITH] = "SOUL_HEART"
	CustomHealthAPI.PersistentData.CharactersThatConvertMaxHealth[EdithRestored.Enums.PlayerType.EDITH_B] =
	"BLACK_HEART"
	CustomHealthAPI.Library.AddCallback(
		"EdithRestored",
		CustomHealthAPI.Enums.Callbacks.CAN_PICK_HEALTH,
		0,
		function(player, key)
			if
				Helpers.IsPlayerEdith(player)
				and CustomHealthAPI.Library.GetInfoOfKey(key, "Type") == CustomHealthAPI.Enums.HealthTypes.RED
			then
				return false
			end
		end
	)
end

local Player = {}
local MinJumpVal = 10
local JumpChargeMul = 1.5
local JumpCharge = 1.5

local function IsPlayerOnGravityGrid(player, position)
	local pos = position or player.Position
	local grid = EdithRestored.Room():GetGridEntityFromPos(pos)
	return not player.CanFly and grid and grid:GetType() == GridEntityType.GRID_GRAVITY
end

---@param player EntityPlayer
---@param pos Vector
---@param force boolean?
---@param bigJump boolean?
---@param outPitfall boolean?
local function EdithJump(player, pos, force, bigJump, outPitfall)
	if not (Helpers.IsPureEdith(player) and getmetatable(pos).__type == "Vector") then return end
	local data = EdithRestored:GetData(player)
	local anim = bigJump and "EdithJumpBig" or "EdithJump"
	if outPitfall then
		anim = bigJump and "EdithPitFallBig" or "EdithPitFall"
	end
	local doQuick = false
	if not outPitfall then
		if force ~= nil then
			doQuick = force
		else
			doQuick = data.BombStomp ~= nil	and player:HasCollectible(CollectibleType.COLLECTIBLE_FAST_BOMBS) or player:HasCollectible(CollectibleType.COLLECTIBLE_ROCKET_IN_A_JAR)
		end
	end
	if doQuick then
		anim = anim .. "Quick"
	end
	player:PlayExtraAnimation(anim)
	player:ResetDamageCooldown()
	player:SetMinDamageCooldown(30)
	data.TargetJumpPos = pos
	data.EdithJumpCharge = 0
	data.EdithTargetMovementPosition = nil
end

local function GetJumpMultStats(player)
	local sprite = player:GetSprite()
	local heightMult, gravityMult = 1, 1
	if sprite:GetAnimation():match("Edith") ~= nil
	and sprite:GetAnimation():match("Big") ~= nil then
		heightMult = 2
		gravityMult = 4
	end
	return heightMult, gravityMult
end

---@param tear EntityTear
local function ChangeToEdithTear(tear)
	tear:ChangeVariant(TearVariant.ROCK)

	local tearColor = tear.Color
	local parentColor = tear.Parent.Color

	tear.Color = Color(
		tearColor.R + 0.8 + (parentColor.R - 1),
		tearColor.G + 1 + (parentColor.G - 1),
		tearColor.B + 1 + (parentColor.B - 1),
		tearColor.A + (parentColor.A - 1),
		tearColor.RO + parentColor.RO,
		tearColor.GO + parentColor.GO,
		tearColor.BO + parentColor.BO
	)
end

local function IsEdithExtraAnim(player)
	local s = player:GetSprite():GetAnimation()
	return s:sub(1, 5) == "Edith"
end

---@param player EntityPlayer
local function CheckEdithsCollisionWithGrid(player, data)
	local effects = player:GetEffects()
	local hasMarsEffect = effects:HasCollectibleEffect(CollectibleType.COLLECTIBLE_MARS)
	local room = EdithRestored.Room()

	local gridEntities = {
		room:GetGridEntityFromPos(player.Position + Vector(-40, 0)), --Left
		room:GetGridEntityFromPos(player.Position + Vector(40, 0)), --Right
		room:GetGridEntityFromPos(player.Position + Vector(0, -40)), --Up
		room:GetGridEntityFromPos(player.Position + Vector(0, 40)), --Down
	}

	for _, gridEntity in pairs(gridEntities) do
		--Only check for collission if the grid entity is the appropiate collission class
		--And if we're moving it it's direction
		--TODO: Maybe it'd be better to check for collission with the grid entity twice?
		if
			gridEntity.CollisionClass ~= 0
			and gridEntity.CollisionClass ~= 5
			and (gridEntity.Position - player.Position)
			:Normalized()
			:DistanceSquared(player.Velocity:Normalized())
			< 0.1
		then
			--Check if player is intersecting with the gridEntity
			--From https://stackoverflow.com/questions/401847/circle-rectangle-collision-detection-intersection
			local isIntersecting
			local circleDistanceX = math.abs(player.Position.X - gridEntity.Position.X)
			local circleDistanceY = math.abs(player.Position.Y - gridEntity.Position.Y)

			if circleDistanceX > 20 + player.Size + 0.1 or circleDistanceY > 20 + player.Size + 0.1 then
				isIntersecting = false
			elseif circleDistanceX <= 20 or circleDistanceY <= 20 then
				isIntersecting = true
			else
				local cornerDistanceSq = (circleDistanceX - 20) ^ 2 + (circleDistanceY - 20) ^ 2
				isIntersecting = cornerDistanceSq <= (player.Size + 0.1) ^ 2
			end

			if isIntersecting then
				if
					gridEntity.CollisionClass == GridCollisionClass.COLLISION_WALL
					or (
						not player:IsFlying()
						and (
							gridEntity.CollisionClass == GridCollisionClass.COLLISION_PIT
							or gridEntity.CollisionClass == GridCollisionClass.COLLISION_SOLID
						)
					)
				then
					--if gridEntity.CollisionClass == GridCollisionClass.COLLISION_WALL then
						player.Velocity = Vector.Zero
						data.EdithTargetMovementPosition = nil
						if hasMarsEffect then
							local marsEffect = effects:GetCollectibleEffect(CollectibleType.COLLECTIBLE_MARS)
							local marsCooldown = marsEffect.Cooldown

							game:ShakeScreen(marsCooldown + 10)
						end
					--end
					data.TriggerMove = false
				end

				--Check if we can open a door
				if gridEntity:GetType() == GridEntityType.GRID_DOOR and room:IsClear() then
					local door = gridEntity:ToDoor()
					if door:IsLocked() then
						door:TryUnlock(player, false)
					end
				end
			end
		end
	end
end

---@param player EntityPlayer
local function CheckEdithsCollisionWithSlots(player, data)
	local slots = Isaac.FindByType(EntityType.ENTITY_SLOT)

	local isCollidingWithSlot = false

	for _, slot in ipairs(slots) do
		if slot:GetData().sizeMulti then
			if
				(math.abs(slot.Position.X - player.Position.X) ^ 2 <= (slot.Size * slot.SizeMulti.X + player.Size) ^ 2)
				and (
					math.abs(slot.Position.Y - player.Position.Y) ^ 2
					<= (slot.Size * slot.SizeMulti.Y + player.Size) ^ 2
				)
			then
				isCollidingWithSlot = true
			end
		else
			if slot.Position:DistanceSquared(player.Position) <= (slot.Size + player.Size) ^ 2 then
				isCollidingWithSlot = true
			end
		end
	end

	if not isCollidingWithSlot then
		return
	end

	player.Velocity = Vector.Zero
	data.EdithTargetMovementPosition = nil
	data.TriggerMove = false
end

local function EdithJupiterEffect(player, data)
	if not player:HasCollectible(CollectibleType.COLLECTIBLE_JUPITER) then return end
	local rng = player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_JUPITER)

	local smokeNum = rng:RandomInt(3) + 1

	for _ = 1, smokeNum, 1 do
		local randomVel = rng:RandomFloat() * 2 - 1
		local spawningVel
		if data.EdithTargetMovementDirection.X == 0 then
			spawningVel = Vector(randomVel, -data.EdithTargetMovementDirection.Y)
		else
			spawningVel = Vector(-data.EdithTargetMovementDirection.X, randomVel)
		end

		local smokeCloud = TSIL.EntitySpecific.SpawnEffect(
			EffectVariant.SMOKE_CLOUD,
			0,
			player.Position,
			spawningVel:Normalized() * 10,
			player
		)
		local randomScale = rng:RandomFloat() * 0.3
		smokeCloud.SpriteScale = Vector(0.5 + randomScale, 0.5 + randomScale)
		smokeCloud:SetTimeout(70)
	end

	local particleNum = rng:RandomInt(4) + 2
	for _ = 1, particleNum, 1 do
		local randomVel = rng:RandomFloat() * 1 - 0.5
		local spawningVel
		if data.EdithTargetMovementDirection.X == 0 then
			spawningVel = Vector(randomVel, -data.EdithTargetMovementDirection.Y)
		else
			spawningVel = Vector(-data.EdithTargetMovementDirection.X, randomVel)
		end

		local waterParticle = TSIL.EntitySpecific.SpawnEffect(
			EffectVariant.WATER_SPLASH,
			1,
			player.Position,
			spawningVel:Normalized() * 10,
			player
		)
		local randomScale = rng:RandomFloat() * 0.3
		waterParticle.SpriteScale = Vector(2 + randomScale, 2 + randomScale)
		waterParticle:SetTimeout(10)
		waterParticle:GetSprite().Color = Color(0.3, 0.42, 0.25)
	end

	sfx:Play(SoundEffect.SOUND_FART)
end

---@param player EntityPlayer
---@param directionStuff number
local function EdithSlideEffects(player, directionStuff)
	local dustVelocity = (-player.Velocity):Normalized() * 10
	local bdType = EdithRestored.Room():GetBackdropType()
	local chap4 = IsChap4()
	local slideSound = chap4 and SoundEffect.SOUND_MEATY_DEATHS or EdithRestored.Enums.SFX.Edith.ROCK_SLIDE
	local slideVolume = chap4 and 0.3 or 1
	local HasWater = EdithRestored.Room():HasWater()
	local variant = HasWater and EffectVariant.BIG_SPLASH or (
		chap4 and EffectVariant.POOF02 or EdithRestored.Enums.Entities.CUSTOM_DUST_CLOUD.Variant
	)
	local subtype = HasWater and 1 or (chap4 and 3 or 0)
	local scale = {
		X = (((not HasWater and chap4) and 0.4) or 1) * directionStuff,
		Y = ((not HasWater and chap4) and 0.25) or 1
	}

	local slideGFX = Isaac.Spawn(
		EntityType.ENTITY_EFFECT,
		variant,
		subtype,
		player.Position,
		Vector.Zero,
		nil
	)

	slideGFX.SpriteScale = Vector(scale.X, scale.Y) * player.SpriteScale.X

	if not HasWater and not chap4 then
		slideGFX.Velocity = dustVelocity
	end

	local tableColorTarget = HasWater and SlideColors.Water or (chap4 and SlideColors.Flesh)

	if tableColorTarget then
		slideGFX.Color = (tableColorTarget[bdType] or tableColorTarget.Default)
	end

	sfx:Play(slideSound, slideVolume)
	game:ShakeScreen(1)

	-- local rockParticleVelocity = Vector(0, 0)

	-- if math.random(2) == 2 then
	-- 	rockParticleVelocity = - (player.Velocity:Rotated(45) / 2)
	-- else
	-- 	rockParticleVelocity = - (player.Velocity:Rotated(-45) / 2)
	-- end

	-- local rockParticleSpawn = player.Position - player.Velocity / 2
	-- rockParticleSpawn = rockParticleSpawn + Vector(0, 20)

	-- local rockParticle = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.TOOTH_PARTICLE, 0,
	-- rockParticleSpawn, rockParticleVelocity, nil)
	-- rockParticle:SetColor(player.Color, -1, -20, false, true)

	-- rockParticle.DepthOffset = -20
end

local JumpAnims = {
	["EdithJump"] = true,
	["EdithJumpQuick"] = true,
	["EdithJumpBig"] = true,
	["EdithJumpBigQuick"] = true,
	["EdithPitFall"] = true,
	["EdithPitFallBig"] = true,
}

---@param playerSprite Sprite
---@return boolean
local function IsEdithPlayingAJumpAnim(playerSprite)
	local anim = playerSprite

	return JumpAnims[anim] or false
end

---@param player EntityPlayer
---@param data table
local function EdithTriggerSlide(player, data, gridMult, forcedDir, forcedVec)
	local isPressingLeft
	local isPressingRight
	local isPressingUp
	local isPressingDown
	local controllerIndex = player.ControllerIndex
	local allowHolding = Helpers.IsPureEdith(player) and EdithRestored:GetDefaultFileSave("AllowHolding")

	-- I can't believe this actually works
	local ActionFunc = allowHolding and Input.IsActionPressed or Input.IsActionTriggered

	isPressingLeft = ActionFunc(ButtonAction.ACTION_LEFT, controllerIndex)
	isPressingRight = ActionFunc(ButtonAction.ACTION_RIGHT, controllerIndex)
	isPressingUp = ActionFunc(ButtonAction.ACTION_UP, controllerIndex)
	isPressingDown = ActionFunc(ButtonAction.ACTION_DOWN, controllerIndex)

	if data.InputBuffer then
		isPressingLeft = isPressingLeft or data.InputBuffer.input == ButtonAction.ACTION_LEFT
		isPressingRight = isPressingRight or data.InputBuffer.input == ButtonAction.ACTION_RIGHT
		isPressingUp = isPressingUp or data.InputBuffer.input == ButtonAction.ACTION_UP
		isPressingDown = isPressingDown or data.InputBuffer.input == ButtonAction.ACTION_DOWN

		data.InputBuffer = nil
	end

	-- There's really a need to return if we aren't pressing anything??
	--If we're not pressing anything, return
	-- if not isPressingLeft and not isPressingRight and not isPressingUp and not isPressingDown then
	-- 	return
	-- end

	local room = EdithRestored.Room()
	local clampedPlayerPos = room:GetGridPosition(room:GetGridIndex(player.Position))
	local targetMovementPosition
	local targetMovementDirection
	local mirrorWorldReverser = Helpers.InMirrorWorld() and -1 or 1
	local gridMove = 40 * Helpers.Round(gridMult, 0)

	if forcedDir then
		local params = {
			[ButtonAction.ACTION_LEFT] = {
				GridMove = Vector(-gridMove, 0) * mirrorWorldReverser,
				Direction = Vector(-1, 0)
			},
			[ButtonAction.ACTION_RIGHT] = {
				GridMove = Vector(gridMove, 0) * mirrorWorldReverser,
				Direction = Vector(1, 0)
			},
			[ButtonAction.ACTION_UP] = {
				GridMove = Vector(0, -gridMove),
				Direction = Vector(0, -1)
			},
			[ButtonAction.ACTION_DOWN] = {
				GridMove = Vector(0, gridMove),
				Direction = Vector(0, 1)
			},
		}

		local ButtomParams = params[forcedDir]

		data.MovementDirection = forcedDir
		targetMovementPosition = clampedPlayerPos + ButtomParams.GridMove
		targetMovementDirection = ButtomParams.Direction
	else
		if isPressingLeft then
			targetMovementPosition = clampedPlayerPos + Vector(-gridMove, 0) * mirrorWorldReverser
			targetMovementDirection = Vector(-1, 0)
		elseif isPressingRight then
			targetMovementPosition = clampedPlayerPos + Vector(gridMove, 0) * mirrorWorldReverser
			targetMovementDirection = Vector(1, 0)
		elseif isPressingDown then
			targetMovementPosition = clampedPlayerPos + Vector(0, gridMove)
			targetMovementDirection = Vector(0, 1)
		elseif isPressingUp then
			targetMovementPosition = clampedPlayerPos + Vector(0, -gridMove)
			targetMovementDirection = Vector(0, -1)
		end
	end

	EdithJupiterEffect(player, data)

	data.EdithTargetMovementPosition = targetMovementPosition

	if forcedVec then
		data.EdithTargetMovementDirection = forcedVec
	else
		data.EdithTargetMovementDirection = targetMovementDirection
	end

	-- data.PreLastEdithPosition = nil
	-- data.LastEdithPosition = nil
end

local function EdithSliding(player, data, hasMarsEffect, hasMegaMush, speedBase, firstFrameOfMovement)
	local effects = player:GetEffects()

	if Helpers.IsPureEdith(player) and not player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and not game:IsPaused() then
		data.EdithJumpCharge = math.max(0, data.EdithJumpCharge - JumpCharge / 2)
	end

	if not hasMarsEffect and data.HadMarsEffect then
		data.EdithTargetMovementPosition = nil
	end

	if not Helpers.CanMove(player) or hasMegaMush then
		data.EdithTargetMovementPosition = nil
		player.Velocity = Vector.Zero
		return
	end

	--If EdithTargetMovementPosition is not nil, we are moving
	--Handle her velocity
	local velocityMagnitude = speedBase * player.MoveSpeed
	if hasMarsEffect then
		velocityMagnitude = velocityMagnitude * 3
		local velocityDirection = (data.EdithTargetMovementDirection):Normalized()
		local vel = velocityDirection * velocityMagnitude
		if IsPlayerOnGravityGrid(player) then
			player.Velocity.X = vel.X
		else
			player.Velocity = vel
		end
	elseif data.EdithTargetMovementPosition then
		if IsPlayerOnGravityGrid(player, data.EdithTargetMovementPosition) then
			data.EdithTargetMovementPosition.Y = player.Position.Y
			player.Velocity.Y = Helpers.Lerp(player.Velocity.Y, 1, 0.1)
		end
		local velocityDirection = (data.EdithTargetMovementPosition - player.Position):Normalized()
		local distanceToTarget = player.Position:DistanceSquared(data.EdithTargetMovementPosition)

		if distanceToTarget < 5 then
			player.Position = data.EdithTargetMovementPosition
			player.Velocity = Vector.Zero
			data.TriggerMove = false
			data.EdithTargetMovementPosition = nil
		elseif (velocityMagnitude * velocityMagnitude) > distanceToTarget then
			--We squared the distace before dummy
			player.Velocity = velocityDirection * math.sqrt(distanceToTarget)
		else
			player.Velocity = velocityDirection * velocityMagnitude
		end
	end

	CheckEdithsCollisionWithGrid(player, data)

	if not firstFrameOfMovement then
		--Don't check for slot collission the first frame, so we can use them and move away
		CheckEdithsCollisionWithSlots(player, data)
	end

	local MovementDir = data.EdithTargetMovementDirection
	local directionStuff = (MovementDir.X == -1 or MovementDir.Y == -1) and -1 or 1

	if data.EdithTargetMovementPosition and not player:IsFlying() and firstFrameOfMovement then
		EdithSlideEffects(player, directionStuff)
	end

	--Store last input in a buffer
	if not firstFrameOfMovement then
		--We need to check if it's the first frame of movement because we'd be recording the first input twice
		local controllerIndex = player.ControllerIndex

		local isPressingLeft = Input.IsActionTriggered(ButtonAction.ACTION_LEFT, controllerIndex)
		local isPressingRight = Input.IsActionTriggered(ButtonAction.ACTION_RIGHT, controllerIndex)
		local isPressingUp = Input.IsActionTriggered(ButtonAction.ACTION_UP, controllerIndex)
		local isPressingDown = Input.IsActionTriggered(ButtonAction.ACTION_DOWN, controllerIndex)

		if isPressingLeft then
			data.InputBuffer = { input = ButtonAction.ACTION_LEFT, frame = 5 }
		elseif isPressingRight then
			data.InputBuffer = { input = ButtonAction.ACTION_RIGHT, frame = 5 }
		elseif isPressingUp then
			data.InputBuffer = { input = ButtonAction.ACTION_UP, frame = 5 }
		elseif isPressingDown then
			data.InputBuffer = { input = ButtonAction.ACTION_DOWN, frame = 5 }
		elseif data.InputBuffer then
			if data.InputBuffer.frame then
				data.InputBuffer.frame = data.InputBuffer.frame - 1
			end

			if data.InputBuffer == 0 then
				data.InputBuffer = nil
			end
		end

		--Also check if we moved
		-- if
		-- 	player.Position:DistanceSquared(data.LastEdithPosition) <= 0.1
		-- 	or (
		-- 		data.PreLastEdithPosition
		-- 		and (
		-- 			player.Position:DistanceSquared(data.PreLastEdithPosition) <= 0.1
		-- 			or data.LastEdithPosition:DistanceSquared(data.PreLastEdithPosition)
		-- 			<= math.min(player.MoveSpeed * 2.5, 2)
		-- 		)
		-- 	)
		-- then
		-- 	--If we barely moved between 2 frames, cancel the movement
		-- 	data.EdithTargetMovementPosition = nil
		-- end
	end

	data.PreLastEdithPosition = data.LastEdithPosition
	data.LastEdithPosition = player.Position

	if not data.EdithTargetMovementPosition then
		effects:RemoveCollectibleEffect(CollectibleType.COLLECTIBLE_MARS)
	end
end

---@param data table
---@return boolean
function EdithRestored:IsEdithSliding(data)
	return data.EdithTargetMovementDirection ~= nil
end

---@param data table
function EdithRestored:StopSlide(data)
	data.EdithTargetMovementPosition = nil
	data.EdithTargetMovementDirection = nil
	data.SlideHitBlacklist = {}
end

---@param player EntityPlayer
function EdithRestored:EdithGridMovement(player, data, speedBase, gridMult, forcedDir, forcedVec)
	local firstFrameOfMovement = false
	local MovementPos = data.EdithTargetMovementPosition
	local effects = player:GetEffects()

	if (player.ControlsEnabled ~= true or Helpers.IsMenuing()) and not MovementPos then return end
	
	local hasMarsEffect = effects:HasCollectibleEffect(CollectibleType.COLLECTIBLE_MARS)
	local hasMegaMush = effects:HasCollectibleEffect(CollectibleType.COLLECTIBLE_MEGA_MUSH)
	local playerSprite = player:GetSprite()

	if IsEdithPlayingAJumpAnim(playerSprite) then return end

	data.SlideCounter = data.SlideCounter or 0

	if data.EdithTargetMovementPosition then	
		data.SlideCounter = data.SlideCounter + 1
	else 
		data.SlideCounter = 0
	end	

	firstFrameOfMovement = data.SlideCounter == 1

	if (not MovementPos and Helpers.CanMove(player) and not hasMegaMush) then
		EdithTriggerSlide(player, data, gridMult, forcedDir, forcedVec)
	end

	if MovementPos then
		EdithSliding(player, data, hasMarsEffect, hasMegaMush, speedBase, firstFrameOfMovement)
	end

	-- print()

	data.HadMarsEffect = hasMarsEffect
	-- data.TriggerMove = false	
end

--- Is this a Tainted Edith function??
function Player:LoadUpdate(isLoading)
	for _, player in ipairs(Helpers.GetPlayers()) do
		player:AddCacheFlags(CacheFlag.CACHE_DAMAGE | CacheFlag.CACHE_SPEED, true)
	end
	if PlayerManager.AnyoneIsPlayerType(EdithRestored.Enums.PlayerType.EDITH) then
		game:GetItemPool():RemoveCollectible(CollectibleType.COLLECTIBLE_GNAWED_LEAF)
	end
end

EdithRestored:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, Player.LoadUpdate)

---@param player EntityPlayer
function Player:ChargeBarRender(player)
	local data = EdithRestored:GetData(player)
	if not Helpers.IsPureEdith(player) or player:GetEffects():HasCollectibleEffect(CollectibleType.COLLECTIBLE_MEGA_MUSH) then return end

	data.EdithJumpCharge = data.EdithJumpCharge or 0
	data.ChargeBar = data.ChargeBar or Sprite("gfx/chargebar.anm2", true)
	data.ChargeBar.Offset = Vector(-12 * player.SpriteScale.X, -35 * player.SpriteScale.Y)
	HudHelper.RenderChargeBar(
		data.ChargeBar,
		math.max(0, data.EdithJumpCharge - MinJumpVal),
		JumpChargeMul * 100,
		EdithRestored.Room():WorldToScreenPosition(player.Position)
	)
end
EdithRestored:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, Player.ChargeBarRender, 0)

function Player:StompRadiusRender()
	if EdithRestored.DebugMode then
		for _, player in ipairs(Helpers.MergeTables({}, Helpers.GetPlayersByType(EdithRestored.Enums.PlayerType.EDITH), Helpers.GetPlayersByCollectible(EdithRestored.Enums.CollectibleType.COLLECTIBLE_BLASTING_BOOTS))) do
			local shape = player:GetDebugShape(true)
			shape:Circle(player.Position, EdithRestored:GetDebugValue("StompRadius"))
		end
	end
end
EdithRestored:AddCallback(ModCallbacks.MC_POST_RENDER, Player.StompRadiusRender)

---Draws a line between from `from` position to `to` position
---@param effect EntityEffect
---@param from Vector
---@param to Vector
---@param color Color
---@param isObscure? boolean
local function drawLine(effect, from, to, color, isObscure)
	local effectData = EdithRestored:GetData(effect)
	effectData.Line = effectData.Line or Sprite("gfx/edith line.anm2", true)
	if not effectData.Line:IsLoaded() then return end

	local targetSprite = effectData.Line
	local diffVector = to - from
	local angle = diffVector:GetAngleDegrees()
	local sectionCount = math.floor(diffVector:Length() / 16) - 1
	local direction = Vector.FromAngle(angle)

	targetSprite:SetFrame("Line", isObscure and 1 or 0)
	targetSprite.Color = color
	targetSprite.Rotation = angle

	local currentPos
	for i = 0, sectionCount do
		currentPos = from + direction * (i * 16)
		targetSprite:Render(Isaac.WorldToScreen(currentPos))
	end
end

local spritePrefix = "gfx/effects/"
---@param target EntityEffect
function Player:TargetJumpRender(target)
	if EdithRestored.Room():GetRenderMode() == RenderMode.RENDER_WATER_REFLECT then return end

	local sprite = target:GetSprite()
	local player = TSIL.Players.GetPlayerFromEntity(target)

	drawLine(target, player.Position, target.Position, target.Color, sprite:GetFrame() == 1)

	if game:IsPaused() then return end
	if not player then return end
	if not Helpers.IsPureEdith(player) then return end

	local data = EdithRestored:GetData(player)
	local targetSprite = data.BombStomp and "target_edith_bomb.png" or "target_edith.png"
	local TargetColor = EdithRestored:GetDefaultFileSave("TargetColor")

	sprite.PlaybackSpeed = 0.05
	sprite:Update()
	sprite:ReplaceSpritesheet(0, spritePrefix .. targetSprite, true)
	
	if TargetColor then
		target.Color = Color(TargetColor.R / 255, TargetColor.G / 255, TargetColor.B / 255, 1, 0, 0, 0)
	else
		target.Color = Color(155 / 255, 0, 0, 1, 0, 0, 0)
	end
end

EdithRestored:AddCallback(
	ModCallbacks.MC_POST_EFFECT_RENDER,
	Player.TargetJumpRender,
	EdithRestored.Enums.Entities.EDITH_TARGET.Variant
)

---@param target EntityEffect
function Player:TargetJumpUpdate(target)
	local player = TSIL.Players.GetPlayerFromEntity(target) ---@cast player EntityPlayer

	if not player or not Helpers.IsPureEdith(player) then
		target:Remove()
		return
	end

	if EdithRestored:GetData(player).TargetJumpPos then
		target.Velocity = Vector.Zero
	else
		local marked = player:GetMarkedTarget()
		if marked then
			target.Position = marked.Position
			target.Velocity = marked.Velocity
		elseif
			Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT)
			and Options.MouseControl
			and Input.GetDeviceNameByIdx(player.ControllerIndex) == "Keyboard"
		then
			target.Position = Input.GetMousePosition(true)
		else
			target.Velocity = target.Velocity + player:GetShootingInput():Resized(12)
			target:MultiplyFriction(0.5)
		end
	end
end

EdithRestored:AddCallback(
	ModCallbacks.MC_POST_EFFECT_UPDATE,
	Player.TargetJumpUpdate,
	EdithRestored.Enums.Entities.EDITH_TARGET.Variant
)

function Player:OnInitPlayer(player)
	-- If the player is Edith it will apply the hood
	if not Helpers.IsPureEdith(player) then return end
	local mySprite = player:GetSprite()
	mySprite:Load(EdithRestored.Enums.PlayerSprites.EDITH, true)
	mySprite:Update()
	-- elseif Helpers.IsTaintedEdith(player) then -- Apply different costume for her tainted variant
		-- if Helpers.IsTaintedEdith(player) then
		-- 	player:ChangePlayerType(EdithRestored.Enums.PlayerType.EDITH)
		-- end
		-- goto EdithCheck
		-- local mySprite = player:GetSprite()
		-- mySprite:Load(EdithRestored.Enums.PlayerSprites.EDITH_B, true)
		-- mySprite:LoadGraphics()
		-- Helpers.ChangeSprite(player, true)
		-- player:SetPocketActiveItem(
		-- 	EdithRestored.Enums.CollectibleType.COLLECTIBLE_THE_CHISEL,
		-- 	ActiveSlot.SLOT_POCKET,
		-- 	false
		-- )
end

EdithRestored:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, Player.OnInitPlayer)

-- Function made to manage Edith's BombStomp state
---@param player EntityPlayer
---@param data table
local function EdithBombLandSetter(player, data)
	if not (Input.IsActionTriggered(ButtonAction.ACTION_DROP, player.ControllerIndex) and JumpLib:CanJump(player) and Helpers.CanMove(player)) then return end
	
	data.BombStomp = not data.BombStomp
end

-- Function made to manage Edith's Bobby Bomb interaction
---@param player EntityPlayer
---@param isJumping boolean	
---@param data table
local function EdithBobbyBombsInteraction(player, isJumping, data)
	if not (isJumping and player:HasCollectible(CollectibleType.COLLECTIBLE_BOBBY_BOMB) and data.BombStomp) then return end
	for _, enemy in	ipairs(Helpers.GetEnemiesInRadius(player.Position, Helpers.GetStompRadius())) do
		enemy.Velocity = enemy.Velocity + (player.Position - enemy.Position):Resized(2)
	end
end

-- Returns a `boolean` depending if Edith can charge her jump
---@param sprite Sprite
---@param isJumping boolean
---@return boolean
local function ShouldChargeEdithJump(sprite, isJumping)
	return (sprite:GetAnimation():sub(1, 9) ~= "EdithJump"
		and not isJumping
		and not Helpers.IsMenuing()
		and not game:IsPaused()
		and game:GetFrameCount() > 1)
end	

-- Edith jump's charge manager
---@param player EntityPlayer
---@param data table
local function EdithJumpChargeManager(player, data)
	local isInstantJumpCharge = EdithRestored.DebugMode and EdithRestored:GetDebugValue("InstantJumpCharge")
	local chargeFormula = (
		isInstantJumpCharge and 100 * JumpChargeMul + MinJumpVal or
		JumpCharge * (player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and 2 or 1)
	)
	local max = 100 * JumpChargeMul + MinJumpVal

	data.EdithJumpCharge = Helpers.Clamp(data.EdithJumpCharge + chargeFormula, 0, max)
end	

-- Function made to manage when Edith is teleporting
---@param player EntityPlayer
---@param sprite Sprite
local function EdithTeleportManager(player, sprite)
	if not sprite:GetAnimation():find("Teleport") then return end
	player.ControlsEnabled = true
	player.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
	player.GridCollisionClass = player.CanFly and EntityGridCollisionClass.GRIDCOLL_WALLS or EntityGridCollisionClass.GRIDCOLL_GROUND
end

---@param player EntityPlayer
---@param data table
local function EdithTargetManager(player, data)
	local edithTarget = data.EdithJumpTarget
	local hasMegaMush = player:GetEffects():HasCollectibleEffect(CollectibleType.COLLECTIBLE_MEGA_MUSH)
	local isBombActionPressed = Input.IsActionTriggered(ButtonAction.ACTION_BOMB, player.ControllerIndex)
	local isJumping = JumpLib:GetData(player).Jumping
	local isJumpFullyCharged = data.EdithJumpCharge >= (100 * JumpChargeMul + MinJumpVal)

	if not Helpers.CanMove(player) or hasMegaMush then return end
	if not isJumpFullyCharged then data.LockBombs = nil return end

	data.LockBombs = true

	if not isBombActionPressed then return end
	if not edithTarget then
		Helpers.SpawnEdithTarget(player)
	elseif JumpLib:CanJump(player) and not isJumping then
		EdithJump(player, edithTarget.Position, nil, player:HasCollectible(CollectibleType.COLLECTIBLE_EPIC_FETUS)
		and (data.BombStomp == false or (data.BombStomp and not player:HasCollectible(CollectibleType.COLLECTIBLE_ROCKET_IN_A_JAR))))
	end
end

---@param player EntityPlayer
---@param sprite Sprite
---@param data table
---@param room Room
local function EdithTrapdoorManager(player, sprite, data, room)
	local GridFromPos = room:GetGridEntityFromPos(player.Position)
	local trapDoorFallFrame = data.TrapDoorFallFrame
	local anim = (type(trapDoorFallFrame) == "boolean" and "EdithTrapdoorFall") or "EdithTrapdoor"

	if not (sprite:GetAnimation() == "Trapdoor") then return end
	if not GridFromPos then return end
	if GridFromPos:GetType() ~= GridEntityType.GRID_TRAPDOOR then return end

	player:StopExtraAnimation()
	player:PlayExtraAnimation(anim)

	if trapDoorFallFrame then
		data.TrapDoorFallFrame = nil 
	end
end

local jumpAnims = {
	["EdithJump"] = true,
	["EdithJumpBig"] = true
}

---@param sprite Sprite
---@return boolean
local function isEdithAnimJumping(sprite)
	local anim = sprite:GetAnimation()
	local isJumpAnim = jumpAnims[anim] or false

	return (isJumpAnim) and not sprite:IsEventTriggered("EdithLanding") 
	or anim == "EdithJumpQuick" or anim:match("EdithPitFall") == "EdithPitFall"
end

---@param sprite Sprite
---@param data table
---@return boolean
local function DidEdithLanded(sprite, data)
	return sprite:IsEventTriggered("EdithJumpFinish")
	and sprite:GetAnimation():match("EdithJump")
	and data.Landed
end

local function EdithLandManager(player, data)
	local IFrames = data.PostLandingKill and 25 or 10
	for _, callback in ipairs(Isaac.GetCallbacks(EdithRestored.Enums.Callbacks.ON_EDITH_STOMP_LANDING_IFRAMES)) do
		local ret = callback.Function(
			callback.Mod,
			player,
			IFrames,
			data.BombStomp or false,
			data.PostLandingKill or false
		)
		if type(ret) == "number" then
			IFrames = Helpers.Round(ret, 0)
		end
	end
	if EdithRestored.DebugMode and EdithRestored:GetDebugValue("UseIFrames") then
		IFrames = EdithRestored:GetDebugValue("IFrames") --[[@as integer]]
	end
	if IFrames > 0 then
		player:ResetDamageCooldown()
		player:SetMinDamageCooldown(IFrames)
	end
	data.Landed = nil
	data.PostLandingKill = nil
end

---@param player EntityPlayer
---@param data table
---@return boolean
local function CanUseRocketJump(player, data)
	return (
		data.BombStomp and
		player:HasCollectible(CollectibleType.COLLECTIBLE_ROCKET_IN_A_JAR) and
		(player:HasCollectible(CollectibleType.COLLECTIBLE_BLOOD_BOMBS) or Helpers.HasBombs(player))
	)
end

---@param player EntityPlayer
---@param sprite Sprite
---@param data table
local function EdithJumpAlt(player, sprite, data)
	if not (sprite:IsEventTriggered("EdithJumpStart") and JumpLib:CanJump(player)) then return end

	local currentAnimation = sprite:GetAnimation()
	local currentFrame = sprite:GetFrame()
	local hasBombs = Helpers.HasBombs(player)
	local hasBloodBombs = player:HasCollectible(CollectibleType.COLLECTIBLE_BLOOD_BOMBS)
	local heightMult, gravityMult = GetJumpMultStats(player)
	local jumpTag = CanUseRocketJump(player, data) and "EdithRocketJump" or "EdithJump"
	
	if (not data.BombStomp) and hasBloodBombs and jumpTag == "EdithRocketJump" and not hasBombs then
		player:TakeDamage(1, DamageFlag.DAMAGE_IV_BAG | DamageFlag.DAMAGE_INVINCIBLE, EntityRef(nil), 60)
		player:PlayExtraAnimation(currentAnimation)
		sprite:SetFrame(currentFrame)
	end
	
	JumpLib:Jump(player, {
		Height = Helpers.GetJumpHeight() * heightMult,
		Speed = Helpers.GetJumpGravity() * gravityMult,
		Flags = JumpLib.Flags.NO_HURT_PITFALL
			| JumpLib.Flags.FAMILIAR_FOLLOW_ORBITALS
			| JumpLib.Flags.FAMILIAR_FOLLOW_TEARCOPYING
			| JumpLib.Flags.DISABLE_COOL_BOMBS
			| JumpLib.Flags.KNIFE_DISABLE_ENTCOLL,
		Tags = { jumpTag },
	})
end

---@param player EntityPlayer
---@param sprite Sprite
---@param data table
local function EdithJumpMove(player, sprite, data)
	if not data.TargetJumpPos then return end
	if not (sprite:IsEventTriggered("EdithJumpStart") and not CanUseRocketJump(player, data)) then return end

	local anim = sprite:GetAnimation()

	if anim == "EdithJumpBig" or anim == "EdithPitFallBig" then
		player.Velocity = Vector.Zero
		player.Position = data.TargetJumpPos
	else
		local posDif = data.TargetJumpPos - player.Position
		player.Velocity = (posDif):Normalized() * (posDif):Length() / 7.7
	end
end

---@param player EntityPlayer
---@param sprite Sprite
---@param data table
---@param room Room
local function EdithJumpGridManager(player, sprite, data, room)
	local grid = room:GetGridEntityFromPos(player.Position)
	if not grid then return end
	if sprite:GetFrame() <= 14 then return end
	if not (
		grid:GetType() == GridEntityType.GRID_TRAPDOOR and
		grid.State == 1 and
		(player.Position - grid.Position):Length() <= 30
	) then return end

	player.Velocity = Vector.Zero
	player.Position = grid.Position
	player.ControlsEnabled = true
	player.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
	player.GridCollisionClass = player.CanFly and EntityGridCollisionClass.GRIDCOLL_WALLS
		or EntityGridCollisionClass.GRIDCOLL_GROUND
	player:StopExtraAnimation()

	data.TrapDoorFallFrame = sprite:GetAnimation():match("Big") == "Big"
	data.TargetJumpPos = nil

	Helpers.RemoveEdithTarget(player)
end

---@param player EntityPlayer
function Player:OnUpdatePlayer(player)
	if not Helpers.IsPureEdith(player) then return end
	local dataP = EdithRestored:RunSave(player)

	if not dataP then return end
	local data = EdithRestored:GetData(player)
	local sprite = player:GetSprite()
	local room = EdithRestored.Room()
	local jumpData = JumpLib:GetData(player)
	local isJumping = jumpData.Jumping

	if (player:IsDead() or player:HasCurseMistEffect()) then
		Helpers.RemoveEdithTarget(player)
		data.EdithJumpCharge = 0
		return 
	end

	if sprite:GetAnimation():find("Walk") then
		sprite:Play(sprite:GetAnimation():match("%w*[Walk]") .. "Down", true)
	end
	---@diagnostic disable-next-line: undefined-field
	player:SetGnawedLeafTimer(0)
	if JumpLib:CanJump(player) then
		EdithRestored:EdithGridMovement(player, data, 5, 1)
	end

	data.EdithJumpCharge = data.EdithJumpCharge or 0

	if ShouldChargeEdithJump(sprite, isJumping) then
		EdithJumpChargeManager(player, data)
	end

	if isEdithAnimJumping(sprite) then
		EdithJumpAlt(player, sprite, data)
		EdithJumpMove(player, sprite, data)
		EdithJumpGridManager(player, sprite, data, room)
	end		

	if DidEdithLanded(sprite, data) then
		EdithLandManager(player, data)
	end

	EdithBombLandSetter(player, data)
	EdithBobbyBombsInteraction(player, isJumping, data)
	EdithTeleportManager(player, sprite)
	EdithTargetManager(player, data)
	EdithTrapdoorManager(player, sprite, data, room)
end
EdithRestored:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, Player.OnUpdatePlayer, 0)

---@param jumpData JumpData
function Player:Landing(player, jumpData, inPit)
	local data = EdithRestored:GetData(player)
	if (not inPit and data.AfterPitfall ~= true) then
		local prevBombStomp = data.BombStomp
		if data.AfterPitfall == false then
			data.BombStomp = nil
		end
		Helpers.Stomp(player, 1, nil, not data.PostRocketRide and data.BombStomp, Helpers.IsPureEdith(player), {Tooth = true})
		if data.AfterPitfall == false then
			data.BombStomp = prevBombStomp
		end
		data.Landed = true
		data.PostRocketRide = nil
		--data.TargetLandPos = Helpers.GetEdithTarget(player).Position
		player.Velocity = Vector.Zero
		Helpers.RemoveEdithTarget(player)
		data.TargetJumpPos = nil
		for _, v in pairs(Isaac.FindInRadius(player.Position, 55, EntityPartition.BULLET)) do
			local projectile = v:ToProjectile() ---@cast projectile EntityProjectile
			local angle = ((player.Position - projectile.Position) * -1):GetAngleDegrees()
			projectile.Velocity = Vector.FromAngle(angle):Resized(10)
			projectile:AddProjectileFlags(ProjectileFlags.CANT_HIT_PLAYER)
			projectile:AddProjectileFlags(ProjectileFlags.HIT_ENEMIES)
		end
		if player:HasCollectible(CollectibleType.COLLECTIBLE_HOW_TO_JUMP) and not data.HTJ then
			data.BombStomp = nil
			EdithJump(player, player.Position, true)
			data.HTJ = true
		elseif
			EdithRestored.Room():GetGridCollisionAtPos(player.Position) == GridCollisionClass.COLLISION_SOLID
			and not player.CanFly
		then
			data.BombStomp = nil
			EdithJump(player, EdithRestored.Room():FindFreePickupSpawnPosition(player.Position, 0, false, false), true)
		else
			data.HTJ = nil
		end
		data.AfterPitfall = nil
	else
		data.HTJ = nil
		data.AfterPitfall = false
	end
end

EdithRestored:AddCallback(
	JumpLib.Callbacks.ENTITY_LAND,
	Player.Landing,
	{ tag = "EdithJump", type = EntityType.ENTITY_PLAYER }
)

---@param player EntityPlayer
---@param jumpData JumpData
---@return boolean?
function Player:Pitfall(player, jumpData)
	local tags = jumpData.Tags
	if not (tags["EdithJump"] or tags["EdithRocketJump"] or tags["SoulEdithJump"] or tags["BlastingBootsJump"]) then return end
	local data = EdithRestored:GetData(player)
	local room = EdithRestored.Room()
	local gridIdx = room:GetGridIndex(player.Position)
	data.TargetJumpPos = nil
	data.AfterPitfall = true
	player.Position = room:GetGridPosition(gridIdx)
	player.Velocity = Vector.Zero
	Helpers.RemoveEdithTarget(player)
	EdithJump(player, room
		:FindFreePickupSpawnPosition(player.Position, player:GetDropRNG():RandomInt(140), false, false), false, player:HasCollectible(CollectibleType.COLLECTIBLE_EPIC_FETUS),
	true)
	return true
end

EdithRestored:AddCallback(
    JumpLib.Callbacks.PRE_PITFALL,
    Player.Pitfall,
    { type = EntityType.ENTITY_PLAYER, player = EdithRestored.Enums.PlayerType.EDITH }
)

---@param player EntityPlayer
---@param jumpData JumpData
function Player:RocketJump(player, jumpData)
	local data = EdithRestored:GetData(player)
	local target = Helpers.GetEdithTarget(player)
	local jump = JumpLib.Internal:GetData(player)
	if target and jumpData.Height <= 15 and jumpData.Fallspeed > 2.5 and jump.Tags and jump.Tags["EdithRocketJump"] then
		local rocketVariant = BombVariant.BOMB_ROCKET
		if player:GetNumGigaBombs() > 0 then
			rocketVariant = BombVariant.BOMB_ROCKET_GIGA
			player:AddGigaBombs(-1)
		elseif not player:HasGoldenBomb() then
			player:AddBombs(-1)
		end
		local rocket = Isaac.Spawn(EntityType.ENTITY_BOMB, rocketVariant, 0, player.Position, Vector.Zero, player)
			:ToBomb()
		rocket.DepthOffset = -40
		rocket.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
		rocket.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
		---@cast rocket EntityBomb
		rocket:SetRocketAngle((target.Position - player.Position):GetAngleDegrees())
		rocket:AddTearFlags(player:GetBombFlags())
		data.Rocket = rocket
		EdithRestored:GetData(rocket).ExplosionTarget = target.Position
		JumpLib:QuitJump(player)
		JumpLib:SetHeight(player, 15, {
			Height = 0,
			Speed = jump.StaticJumpSpeed,
			Flags = JumpLib.Flags.NO_HURT_PITFALL
				| JumpLib.Flags.FAMILIAR_FOLLOW_ORBITALS
				| JumpLib.Flags.FAMILIAR_FOLLOW_TEARCOPYING
				| JumpLib.Flags.DISABLE_COOL_BOMBS,
			Tags = { "EdithRocketRiding" },
		})
		Helpers.RemoveEdithTarget(player)
		data.TargetJumpPos = nil
	end
end

EdithRestored:AddCallback(
	JumpLib.Callbacks.ENTITY_UPDATE_60,
	Player.RocketJump,
	{ tag = "EdithRocketJump", type = EntityType.ENTITY_PLAYER, player = EdithRestored.Enums.PlayerType.EDITH }
)

---@param player EntityPlayer
---@param jumpData JumpData
function Player:RocketRide(player, jumpData)
	local data = EdithRestored:GetData(player)
	local jump = JumpLib.Internal:GetData(player)
	if jump.Height <= 15 and data.Rocket ~= nil and data.Rocket:Exists() then
		jump.Height = 15
		jump.Fallspeed = 0
		player.Position = data.Rocket.Position
	end
end

EdithRestored:AddCallback(
	JumpLib.Callbacks.ENTITY_UPDATE_60,
	Player.RocketRide,
	{ tag = "EdithRocketRiding", type = EntityType.ENTITY_PLAYER, player = EdithRestored.Enums.PlayerType.EDITH }
)

---@param bomb EntityBomb
function Player:RocketTarget(bomb)
	if not (bomb.Variant == BombVariant.BOMB_ROCKET or bomb.Variant == BombVariant.BOMB_ROCKET_GIGA) then return end
		local bombData = EdithRestored:GetData(bomb)
	if not bombData.ExplosionTarget then return end
	local player = TSIL.Players.GetPlayerFromEntity(bomb)
	local pData = EdithRestored:GetData(player)
	if not
		(player
		and Helpers.IsPlayerEdith(player:ToPlayer(), true, false)
		and pData.Rocket
		and GetPtrHash(pData.Rocket) == GetPtrHash(bomb))
	then return end

	if (bomb.Position - bombData.ExplosionTarget):Length() <= bomb.Velocity:Length() then
		bomb:SetExplosionCountdown(0)
	end

	if not bomb:GetSprite():IsPlaying("Explode") then return end
	pData.PostRocketRide = true
	JumpLib:QuitJump(player)
	EdithJump(
		player,
		EdithRestored.Room()
		:FindFreePickupSpawnPosition(bomb.Position - bomb.Velocity:Resized(20), 0, false, false),
		true
	)
	player:GetSprite():SetFrame(3)
	JumpLib:SetHeight(player, 15, {
		Height = Helpers.GetJumpHeight() / 2,
		Speed = Helpers.GetJumpGravity(),
		Flags = JumpLib.Flags.NO_HURT_PITFALL
			| JumpLib.Flags.FAMILIAR_FOLLOW_ORBITALS
			| JumpLib.Flags.FAMILIAR_FOLLOW_TEARCOPYING
			| JumpLib.Flags.DISABLE_COOL_BOMBS,
		Tags = { "EdithJump" },
	})
	pData.Rocket = nil
end

EdithRestored:AddCallback(ModCallbacks.MC_POST_BOMB_UPDATE, Player.RocketTarget)

---@param entity Entity
---@param amount number
---@param flags DamageFlag | integer
---@param source EntityRef
---@param cd integer
---@return boolean?
function Player:DamageHandling(entity, amount, flags, source, cd)
	if entity and entity:ToPlayer() and Helpers.IsPlayerEdith(entity:ToPlayer(), true, true) then
		local player = entity:ToPlayer()
		local data = EdithRestored:GetData(player)
		if flags & DamageFlag.DAMAGE_PITFALL > 0 then
			data.EdithTargetMovementPosition = nil
		end
		data.TargetJumpPos = nil

		data.HTJ = nil
		data.PostLandingKill = nil
		data.Landed = nil
		player.Velocity = Vector.Zero
	end
end

EdithRestored:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, Player.DamageHandling, EntityType.ENTITY_PLAYER)

---@param player EntityPlayer
---@param amount number
---@param flags DamageFlag | integer
---@param source EntityRef
---@param cd integer
---@return boolean?
function Player:DamageHandling2(player, amount, flags, source, cd)
	if not Helpers.IsPureEdith(player) then return end
	local sprite = player:GetSprite()
	if not (sprite:GetAnimation():match("Edith") and sprite:WasEventTriggered("EdithLanding")) then return end
	if flags & DamageFlag.DAMAGE_INVINCIBLE > 0 or flags & DamageFlag.DAMAGE_RED_HEARTS > 0 then return end

	return false
end

EdithRestored:AddCallback(ModCallbacks.MC_PRE_PLAYER_TAKE_DMG, Player.DamageHandling2)

---@param entity Entity
---@param amount number
---@param flags DamageFlag | integer
---@param source EntityRef
---@param cd integer
function Player:IFAfterFromJump(entity, amount, flags, source, cd)
	if not 
		(Helpers.IsEnemy(entity, true)
		and entity:HasMortalDamage()
		and source.Entity
		and source.Entity:ToPlayer()
		and flags == DamageFlag.DAMAGE_EXPLOSION | DamageFlag.DAMAGE_CRUSH)
	then return end
	local player = source.Entity:ToPlayer()
	---@cast player EntityPlayer
	local data = EdithRestored:GetData(player)
	data.PostLandingKill = true
end

EdithRestored:AddCallback(ModCallbacks.MC_POST_ENTITY_TAKE_DMG, Player.IFAfterFromJump)

function Player:edith_Stats(player, cacheFlag)
	if Helpers.IsPureEdith(player) then -- If the player is Edith it will apply her specific stats
		if cacheFlag == CacheFlag.CACHE_DAMAGE then
			player.Damage = player.Damage * 1.1
		end
	--elseif Helpers.IsTaintedEdith(player) then -- If the player is Tainted Edith ^^
	--	Helpers.ChangePepperValue(player)
	end
	if cacheFlag == CacheFlag.CACHE_SPEED and Helpers.IsPlayerEdith(player) 
	and not EdithRestored.Room():HasCurseMist() then
		player.MoveSpeed = math.max(0.3, player.MoveSpeed)
	end
end

EdithRestored:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, Player.edith_Stats)

local function ChangeSlotSprite(slot)
	local sprite = slot:GetSprite()
	if sprite:GetLayer(0):GetSpritesheetPath() ~= "gfx/characters/costumes/Character_001_TaintedRedith.png" then
		sprite:ReplaceSpritesheet(0, "gfx/characters/costumes/Character_001_TaintedRedith.png")
		sprite:LoadGraphics()
	end
end

--- This should be remade to only took account the first player, afaik, the tainted character in closet will always be the first's
function Player:Home()
	if
		Helpers.IsPureEdith(Isaac.GetPlayer(0))
		and level:GetCurrentRoomIndex() == 94
		and level:GetStage() == LevelStage.STAGE8
		and not Isaac.GetPersistentGameData():Unlocked(EdithRestored.Enums.Achievements.Characters.TAINTED)
		and EdithRestored.Room():IsFirstVisit()
		and #Isaac.FindByType(EntityType.ENTITY_SLOT, SlotVariant.HOME_CLOSET_PLAYER) == 0
	then
		local tab = Helpers.MergeTables({}, Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE), Isaac.FindByType(EntityType.ENTITY_SHOPKEEPER))
		if #tab > 0 then
			local entity = tab[1]
			entity:Remove()
			Isaac.Spawn(EntityType.ENTITY_SLOT, SlotVariant.HOME_CLOSET_PLAYER, EdithRestored.Enums.PlayerType.EDITH_B, entity.Position, Vector.Zero, nil)
		end
	end
end
--EdithRestored:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, Player.Home)

---@param slot EntitySlot
function Player:TaintedSlot(slot)
	if slot.SubType == EdithRestored.Enums.PlayerType.EDITH_B then
		ChangeSlotSprite(slot)
	end
end
--EdithRestored:AddCallback(ModCallbacks.MC_POST_SLOT_UPDATE, Player.TaintedSlot, SlotVariant.HOME_CLOSET_PLAYER)

function Player:NewRoom()
	for i = 0, game:GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(i)
		local data = EdithRestored:GetData(player)
		--No need to check for edith here because for other players its gonna be nil anyways
		data.EdithTargetMovementPosition = nil
		if Helpers.IsPureEdith(player) then
			player.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
			player.GridCollisionClass = player.CanFly and EntityGridCollisionClass.GRIDCOLL_WALLS
				or EntityGridCollisionClass.GRIDCOLL_GROUND
			data.TrapDoorFall = nil
			JumpLib:QuitJump(player)
		end

		Helpers.RemoveEdithTarget(player)
		data.TargetJumpPos = nil

		data.HTJ = nil
		data.PostLandingKill = nil
		data.Landed = nil
		data.PreJumpPosition = nil
		data.AfterPitfall = nil
	end
end

EdithRestored:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, Player.NewRoom)

---@param collider Entity
function Player:OnCollectibleCollission(_, collider)
	local player = collider:ToPlayer() 

	if not player then return end
	if not Helpers.IsPureEdith(player) then return end

	local data = EdithRestored:GetData(player)
	if not data.EdithTargetMovementPosition then return end

	player.Velocity = Vector.Zero
	data.EdithTargetMovementPosition = nil
end

EdithRestored:AddCallback(
	ModCallbacks.MC_PRE_PICKUP_COLLISION,
	Player.OnCollectibleCollission,
	PickupVariant.PICKUP_COLLECTIBLE
)

---@param collider Entity
function Player:OnMegaChestCollision(_, collider)
	local player = collider:ToPlayer()

	if not player then return end
	if not Helpers.IsPureEdith(player) then return end

	local data = EdithRestored:GetData(player)
	if not data.EdithTargetMovementPosition then return end

	player.Velocity = Vector.Zero
	data.EdithTargetMovementPosition = nil
end

EdithRestored:AddCallback(
	ModCallbacks.MC_PRE_PICKUP_COLLISION,
	Player.OnMegaChestCollision,
	PickupVariant.PICKUP_MEGACHEST
)

---@param entity EntityNPC
---@param collider Entity
function Player:OnNPCCollision(entity, collider)
	local player = collider:ToPlayer()

	if not player then return end
	if not (Helpers.IsPureEdith(player) --[[or Helpers.IsTaintedEdith(player)]]) then return end

	--We can only push enemies with less than 10 mass (arbitrary value, requires testing)
	if entity.Mass < 10 then return end

	local data = EdithRestored:GetData(player)
	if not data.EdithTargetMovementPosition then return end

	if entity.Type == EntityType.ENTITY_SHOPKEEPER then
		return
	end

	if entity.Type == EntityType.ENTITY_FIREPLACE and data.SlideCounter < (5 / player.MoveSpeed) then
		return
	end
	player.Velocity = Vector.Zero
	data.EdithTargetMovementPosition = nil
end

EdithRestored:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, Player.OnNPCCollision)

local tearsToNotChange = {
    [TearVariant.TOOTH] = true,
    [TearVariant.BOBS_HEAD] = true,
    [TearVariant.SCHYTHE] = true,
    [TearVariant.CHAOS_CARD] = true,
    [TearVariant.NAIL] = true,
    [TearVariant.DIAMOND] = true,
    [TearVariant.MULTIDIMENSIONAL] = true,
    [TearVariant.STONE] = true,
    [TearVariant.BOOGER] = true,
    [TearVariant.EGG] = true,
    [TearVariant.RAZOR] = true,
    [TearVariant.BONE] = true,
    [TearVariant.BLACK_TOOTH] = true,
    [TearVariant.NEEDLE] = true,
    [TearVariant.BELIAL] = true,
    [TearVariant.EYE] = true,
    [TearVariant.EYE_BLOOD] = true,
    [TearVariant.BALLOON] = true,
    [TearVariant.BALLOON_BRIMSTONE] = true,
    [TearVariant.BALLOON_BOMB] = true,
    [TearVariant.FIST] = true,
    [TearVariant.KEY] = true,
    [TearVariant.KEY_BLOOD] = true,
    [TearVariant.ERASER] = true,
    [TearVariant.FIRE] = true,
    [TearVariant.SWORD_BEAM] = true,
    [TearVariant.SPORE] = true,
    [TearVariant.TECH_SWORD_BEAM] = true,
    [TearVariant.FETUS] = true,
    [TearVariant.ICE] = true
}

---@param tear EntityTear
---@return boolean
local function TearsToNotChange(tear)
	return tearsToNotChange[tear.Variant] or false
end

---@param tear EntityTear
function Player:OnEdithFireTear(tear)
	local player = TSIL.Players.GetPlayerFromEntity(tear)

	if not player then return end
	if not Helpers.IsPureEdith(player) or player:HasCurseMistEffect() or TearsToNotChange(tear) then return end

	ChangeToEdithTear(tear)
	tear.Scale = tear.Scale * 0.9
	tear.SpriteScale = tear.SpriteScale * 0.9
end

EdithRestored:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, Player.OnEdithFireTear)


local MovementActions = {
	[ButtonAction.ACTION_LEFT] = { Direction = Vector(-1, 0), Return = 0 },
	[ButtonAction.ACTION_RIGHT] = { Direction = Vector(1, 0), Return = 0 },
	[ButtonAction.ACTION_UP] = { Direction = Vector(0, -1), Return = 0 },
	[ButtonAction.ACTION_DOWN] = { Direction = Vector(0, 1), Return = 0 },
}

local function PonyOverride(player, data, actions)
	local movementDirection = data.EdithTargetMovementDirection
	local forceInput = movementDirection:DistanceSquared(actions.Direction) == 0

	if not forceInput then return end
	data.ForceMovementInput = data.ForceMovementInput - 1
	if data.ForceMovementInput > 0 then return end
	if data.PonyItem then
		player:UseActiveItem(data.PonyItem, UseFlag.USE_NOANIM)
		data.PonyItem = nil
	end

	data.ForceMovementInput = nil

	return 1
end

---@param entity Entity
---@param hook InputHook
---@param button ButtonAction
---@return boolean|number?
function Player:EdithMovement(entity, hook, button)
	if not (entity and not entity:IsDead()) then return end
	local player = entity:ToPlayer()

	if not player then return end
	if not Helpers.IsPlayerEdith(player) then return end
	if player:GetEffects():HasCollectibleEffect(CollectibleType.COLLECTIBLE_MEGA_MUSH) or player:HasCurseMistEffect() then return end

	local OnlyStomps = EdithRestored:GetDefaultFileSave("OnlyStomps")
	local data = EdithRestored:GetData(player)
	local actions = MovementActions[button]

	if hook == InputHook.GET_ACTION_VALUE and actions then
		return data.ForceMovementInput and PonyOverride(player, data, actions) or actions.Return
	end

	if hook == InputHook.GET_ACTION_VALUE then return end
	if IsEdithExtraAnim(player) then
		return false
	end
	if button == ButtonAction.ACTION_BOMB and (data.LockBombs or not OnlyStomps) then
		data.LockBombs = nil
		return false
	end
end

EdithRestored:AddPriorityCallback(ModCallbacks.MC_INPUT_ACTION, CallbackPriority.EARLY, Player.EdithMovement)

function Player:PreUsePony(item, _, player)
	if item ~= CollectibleType.COLLECTIBLE_PONY and item ~= CollectibleType.COLLECTIBLE_WHITE_PONY then
		return
	end
	if not Helpers.IsPureEdith(player) then
		return
	end

	local data = EdithRestored:GetData(player)

	if not data.ForceMovementInput then
		data.ForceMovementInput = 3
		data.PonyItem = item
		return true
	end
end

EdithRestored:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, Player.PreUsePony)

---@param laser EntityLaser
function Player:OnMontezumaLaserInit(laser)
	if laser.SpawnerEntity and laser.SpawnerEntity:ToPlayer() then
		laser.Visible = false
	end
end

EdithRestored:AddCallback(ModCallbacks.MC_POST_LASER_UPDATE, Player.OnMontezumaLaserInit, LaserVariant.THICK_BROWN)

---@param laser EntityLaser
function Player:OnMontezumaLaserUpdate(laser)
	--12 is poop laser variant
	--if laser.Variant ~= LaserVariant.THICK_BROWN then laser.Visible = true; return end
	if laser.MaxDistance ~= 120 then
		laser.Visible = true
		return
	end
	if not laser.SpawnerEntity or not laser.SpawnerEntity:ToPlayer() then
		laser.Visible = true
		return
	end

	local player = laser.SpawnerEntity:ToPlayer()
	local data = EdithRestored:GetData(player)

	if not Helpers.IsPureEdith(player) then
		laser.Visible = true
		return
	end

	local laserData = laser:GetData()
	if not laserData.IsFakeMontezumaLaserEdith then
		local spawningRotation
		if not data.EdithTargetMovementDirection then
			spawningRotation = 180
		else
			spawningRotation = (-data.EdithTargetMovementDirection):GetAngleDegrees()
		end

		local newLaser = EntityLaser.ShootAngle(12, player.Position, spawningRotation, laser.Timeout, Vector.Zero, player)
		newLaser:SetMaxDistance(laser.MaxDistance)

		newLaser:GetData().IsFakeMontezumaLaserEdith = true
		newLaser:GetData().TargetRotation = spawningRotation

		laser:Remove()
		return
	end
	laser.Visible = true

	--Shoot corn
	local rng = player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_MONTEZUMAS_REVENGE)
	if rng:RandomInt(100) < 15 then
		local baseVelocityAmount = 7 + rng:RandomFloat() * 5
		local baseVelocity = Vector(-baseVelocityAmount, 0)
		if data.EdithTargetMovementDirection then
			---@diagnostic disable-next-line: cast-local-type
			baseVelocity = -data.EdithTargetMovementDirection * baseVelocityAmount
		end
		local randomOffset = rng:RandomFloat() * 10 - 5

		local spawningVel
		if baseVelocity.X == 0 then
			spawningVel = Vector(randomOffset, baseVelocity.Y)
		else
			spawningVel = Vector(baseVelocity.X, randomOffset)
		end

		local cornProjectile = Isaac.Spawn(
			EntityType.ENTITY_PROJECTILE,
			ProjectileVariant.PROJECTILE_CORN,
			0,
			player.Position,
			spawningVel,
			nil
		)
		cornProjectile = cornProjectile:ToProjectile()

		cornProjectile:AddProjectileFlags(ProjectileFlags.CANT_HIT_PLAYER | ProjectileFlags.HIT_ENEMIES)
		cornProjectile.CollisionDamage = 6
		cornProjectile.FallingSpeed = 0.65
		cornProjectile.Height = -22
	end

	if not data.EdithTargetMovementDirection then
		return
	end

	--Rotation the laser should have
	local trueRotation = (-data.EdithTargetMovementDirection):GetAngleDegrees()

	if laser:GetData().TargetRotation ~= trueRotation then
		--Rotate
		local chosenRotation
		local laserToTrue = trueRotation - laser.Angle
		local trueToLaser = trueRotation + laser.Angle
		if laserToTrue == 0 then
			laserToTrue = math.maxinteger
		end
		if trueToLaser == 0 then
			trueToLaser = math.maxinteger
		end

		if laserToTrue == math.maxinteger and trueToLaser == math.maxinteger then
			chosenRotation = 0
		elseif math.min(math.abs(laserToTrue), math.abs(trueToLaser)) == math.abs(laserToTrue) then
			chosenRotation = laserToTrue
		else
			chosenRotation = trueToLaser
		end

		local chosenVelocity = 10
		if chosenRotation < 0 then
			chosenVelocity = -chosenVelocity
		end

		laser:SetActiveRotation(0, chosenRotation, chosenVelocity, false)
		laser:GetData().TargetRotation = trueRotation
	end
end

EdithRestored:AddCallback(ModCallbacks.MC_POST_LASER_UPDATE, Player.OnMontezumaLaserUpdate, LaserVariant.THICK_BROWN)

---@param effect EntityEffect
function Player:OnCustomDustInit(effect)
	local dustData = effect:GetData()
	local Rotation = math.random(2) == 2 and 1 or -1
	local color = effect.Color
	local rng = effect:GetDropRNG()

	dustData.RotationDir = Rotation * (rng:RandomFloat() + 0.7) * 3
	dustData.AnimFrame = rng:RandomInt(8) - 1
	effect:GetSprite():SetFrame("Clouds", dustData.AnimFrame)

	color:SetTint(1, 1, 1, 0.7)
	effect.Color = color
end

EdithRestored:AddCallback(
	ModCallbacks.MC_POST_EFFECT_INIT,
	Player.OnCustomDustInit,
	EdithRestored.Enums.Entities.CUSTOM_DUST_CLOUD.Variant
)

---@param effect EntityEffect
function Player:OnCustomDustCloudUpdate(effect)
	local data = effect:GetData()
	effect.SpriteRotation = effect.SpriteRotation + data.RotationDir
	effect.SpriteScale = effect.SpriteScale + Vector.One * 0.05
	local color = effect.Color
	color:SetTint(1, 1, 1, color.A - 0.1)
	effect.Color = color

	effect:GetSprite():SetFrame("Clouds", data.AnimFrame)

	if effect.Color.A <= 0 then
		effect:Remove()
	end
end

EdithRestored:AddCallback(
	ModCallbacks.MC_POST_EFFECT_UPDATE,
	Player.OnCustomDustCloudUpdate,
	EdithRestored.Enums.Entities.CUSTOM_DUST_CLOUD.Variant
)

---@param player EntityPlayer
function Player:AccessToMirrorWorld(player)
	if not Helpers.IsPureEdith(player) and player:GetEffects():HasNullEffect(NullItemID.ID_LOST_CURSE) then return end

	local dimension = Helpers.InMirrorWorld() and 0 or 1

	for _, Door in ipairs(TSIL.Doors.GetDoorsToRoomIndex(-100)) do
		if Door.State ~= 1 then goto continue end
		if player.Position:Distance(Door.Position) > 30 then goto continue end

		game:StartRoomTransition(
			level:GetCurrentRoomIndex(),
			Door.Slot % 4,
			RoomTransitionAnim.FADE_MIRROR,
			player,
			dimension
		)
		level.LeaveDoor = Door.Slot
		::continue::
	end
end
EdithRestored:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, Player.AccessToMirrorWorld)

---@param player EntityPlayer
function Player:OnInitPlayerWithShaker(player)
	if not Isaac.GetPersistentGameData():Unlocked(EdithRestored.Enums.Achievements.CompletionMarks.SALT_SHAKER) then
		player:RemoveCollectible(EdithRestored.Enums.CollectibleType.COLLECTIBLE_SALT_SHAKER)
	end
end

EdithRestored:AddCallback(
	ModCallbacks.MC_PLAYER_INIT_POST_LEVEL_INIT_STATS,
	Player.OnInitPlayerWithShaker,
	EdithRestored.Enums.PlayerType.EDITH
)

--Wouldnt be easier to just call this in post_effect_update???
function Player:TargetCamera()
	local list = {}
	for _, entity in
	ipairs(
		Isaac.FindByType(
			EdithRestored.Enums.Entities.EDITH_TARGET.Type,
			EdithRestored.Enums.Entities.EDITH_TARGET.Variant
		)
	)
	do
		list[#list + 1] = entity
	end
	if #list > 0 then
		for _, player in ipairs(Helpers.GetPlayers(true)) do
			list[#list + 1] = player
			if player:GetFocusEntity() then
				list[#list + 1] = player:GetFocusEntity()
			end
		end
		local minx, miny, maxx, maxy = 9999, 9999, -9999, -9999
		for _, ent in ipairs(list) do
			minx = math.min(minx, ent.Position.X)
			miny = math.min(miny, ent.Position.Y)
			maxx = math.max(maxx, ent.Position.X)
			maxy = math.max(maxy, ent.Position.Y)
		end
		local camera = EdithRestored.Room():GetCamera()
		camera:SetFocusPosition(Vector((maxx + minx), (maxy + miny)) / 2)
	end
end

EdithRestored:AddCallback(ModCallbacks.MC_POST_UPDATE, Player.TargetCamera)

function Player:OnStompBloodBombs(player)
	if not Helpers.HasBombs(player) then
		player:TakeDamage(1, DamageFlag.DAMAGE_IV_BAG | DamageFlag.DAMAGE_INVINCIBLE, EntityRef(nil), 60)
		return true
	end
end

EdithRestored:AddPriorityCallback(
	EdithRestored.Enums.Callbacks.DO_STOMP_EXPLOSION,
	CallbackPriority.LATE,
	Player.OnStompBloodBombs,
	{ Item = CollectibleType.COLLECTIBLE_BLOOD_BOMBS }
)

---@param player EntityPlayer
---@param config PassedJumpConfig
function Player:PreJump(player, config)
	EdithRestored:GetData(player).EdithTargetMovementPosition = nil
end

EdithRestored:AddCallback(
	JumpLib.Callbacks.PRE_ENTITY_JUMP,
	Player.PreJump,
	{ type = EntityType.ENTITY_PLAYER, player = EdithRestored.Enums.PlayerType.EDITH }
)

---@param itemConfigItem ItemConfigItem
---@param player EntityPlayer
---@param itemStateOnly boolean
function Player:ChangePlayerGfx(itemConfigItem, player, itemStateOnly)
	if not player:IsCoopGhost() then
		local sprite = player:GetSprite()
		local edithFile = EdithRestored.Enums.PlayerSprites.EDITH
		local edithBFile = EdithRestored.Enums.PlayerSprites.EDITH_B
		if Helpers.IsPlayerEdith(player) then
			local animationFile = "gfx/redith"
			if Helpers.IsTaintedEdith(player) then
				animationFile = animationFile.."_b"
			end
			animationFile = animationFile..".anm2"
			if sprite:GetFilename() ~= animationFile then
				sprite:Load(animationFile, true)
			end
			if Helpers.IsPureEdith(player) then
				if itemConfigItem.ID ~= EdithRestored.Enums.Costumes.EDITH_HOOD and itemConfigItem:IsNull() or 
				not itemConfigItem:IsNull() then
					local sprite = player:GetSprite()
					local bodyColor = player:GetBodyColor()
					local color = HoodColorList[bodyColor] or ""
					if EdithRestored.Room():HasCurseMist() then
						color = "_Human"
					end
					Helpers.ChangeHoodSprite(player, "gfx/characters/costumes/Character_001_Redith_Hood" .. color .. ".png")
					for i = 0, 14 do
						if i ~= 13 then
							sprite:ReplaceSpritesheet(i, "gfx/characters/costumes/Character_001_Redith" .. color .. ".png")
						end
					end
					sprite:LoadGraphics()
				end
			else

			end
		elseif sprite:GetFilename() == edithFile or sprite:GetFilename() == edithBFile then
			sprite:Load("gfx/001.000_Player.anm2", true)
		end
	end
end
EdithRestored:AddPriorityCallback(ModCallbacks.MC_POST_PLAYER_ADD_COSTUME, CallbackPriority.IMPORTANT, Player.ChangePlayerGfx)
EdithRestored:AddPriorityCallback(ModCallbacks.MC_POST_PLAYER_REMOVE_COSTUME, CallbackPriority.IMPORTANT, Player.ChangePlayerGfx)
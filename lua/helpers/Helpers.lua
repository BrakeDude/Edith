local Helpers = {}
local game = EdithRestored.Game
local sfx = EdithRestored.SFX
local itemConfig = EdithRestored.ItemConfig
local itemPool = EdithRestored.ItemPool

local stompPoolsList = { Items = {}, Trinkets = {} }
local turretList = {
	{ 831, 10, -1 },
	{ 835, 10, -1 },
	{ 887, -1, -1 },
	{ 951, -1, -1 },
	{ 815, -1, -1 },
	{ 306, -1, -1 },
	{ 837, -1, -1 },
	{ 42, -1, -1 },
	{ 201, -1, -1 },
	{ 202, -1, -1 },
	{ 203, -1, -1 },
	{ 235, -1, -1 },
	{ 236, -1, -1 },
	{ 804, -1, -1 },
	{ 809, -1, -1 },
	{ 68, -1, -1 },
	{ 864, -1, -1 },
	{ 44, -1, -1 },
	{ 218, -1, -1 },
	{ 877, -1, -1 },
	{ 893, -1, -1 },
	{ 915, -1, -1 },
	{ 291, -1, -1 },
	{ 295, -1, -1 },
	{ 404, -1, -1 },
	{ 409, -1, -1 },
	{ 903, -1, -1 },
	{ 293, -1, -1 },
}

---@param player EntityPlayer
local function RemoveStoreCreditFromPlayer(player) -- Partially from FF
	local t0 = player:GetTrinket(0)
	local t1 = player:GetTrinket(1)

	if t0 & TrinketType.TRINKET_ID_MASK == TrinketType.TRINKET_STORE_CREDIT then
		player:TryRemoveTrinket(TrinketType.TRINKET_STORE_CREDIT)
		return
	elseif t1 & TrinketType.TRINKET_ID_MASK == TrinketType.TRINKET_STORE_CREDIT then
		player:TryRemoveTrinket(TrinketType.TRINKET_STORE_CREDIT)
		return
	end
	player:TryRemoveSmeltedTrinket(TrinketType.TRINKET_STORE_CREDIT)
end

---@param player EntityPlayer
local function TryRemoveStoreCredit(player)
	if EdithRestored.Room():GetType() == RoomType.ROOM_SHOP then
		if player:HasTrinket(TrinketType.TRINKET_STORE_CREDIT) then
			RemoveStoreCreditFromPlayer(player)
		else
			for _, player in
				ipairs(Helpers.Filter(Helpers.GetPlayers(), function(_, player)
					return player:HasTrinket(TrinketType.TRINKET_STORE_CREDIT)
				end))
			do
				RemoveStoreCreditFromPlayer(player)
				return
			end
		end
	end
end

---@param enemy Entity
function Helpers.HereticBattle(enemy)
	local room = EdithRestored.Room()
	if room:GetType() == RoomType.ROOM_BOSS and room:GetBossID() == 81 and enemy.Type == EntityType.ENTITY_EXORCIST then
		return true
	end
	return false
end

---@param enemy Entity
function Helpers.IsTurret(enemy)
	for _, e in ipairs(turretList) do
		if e[1] == enemy.Type and (e[2] == -1 or e[2] == enemy.Variant) and (e[3] == -1 or e[3] == enemy.SubType) then
			return true
		end
	end
	return false
end

---@param player EntityPlayer
---@return boolean
function Helpers.IsLost(player)
	return player:GetHealthType() == HealthType.NO_HEALTH and player:GetPlayerType() ~= PlayerType.PLAYER_THESOUL_B
end

---@param player EntityPlayer
---@return boolean
function Helpers.IsGhost(player)
	return player:GetEffects():HasNullEffect(NullItemID.ID_LOST_CURSE) or Helpers.IsLost(player)
end

---@param player EntityPlayer
---@param pickup EntityPickup
---@return boolean
function Helpers.CanCollectCustomShopPickup(player, pickup)
	if
		pickup:IsShopItem()
			and (pickup.Price > 0 and player:GetNumCoins() < pickup.Price or not player:IsExtraAnimationFinished())
		or pickup.Wait > 0
	then
		return false
	end
	return true
end

---@param player EntityPlayer
---@param pickup EntityPickup
---@return boolean?
function Helpers.CollectCustomPickup(player, pickup)
	if not Helpers.CanCollectCustomShopPickup(player, pickup) then
		return pickup:IsShopItem()
	end
	if not pickup:IsShopItem() then
		pickup:GetSprite():Play("Collect")
		pickup:Die()
	else
		if pickup.Price >= 0 or pickup.Price == PickupPrice.PRICE_FREE or pickup.Price == PickupPrice.PRICE_SPIKES then
			if pickup.Price == PickupPrice.PRICE_SPIKES and not Helpers.IsGhost(player) then
				local tookDamage = player:TakeDamage(2.0, 268435584, EntityRef(nil), 30)
				if not tookDamage then
					return pickup:IsShopItem()
				end
			end
			if pickup.Price >= 0 then
				player:AddCoins(-pickup.Price)
			end
			CustomHealthAPI.Library.TriggerRestock(pickup)
			TryRemoveStoreCredit(player)
			pickup:Remove()
			player:AnimatePickup(pickup:GetSprite(), true)
		end
	end
	if pickup.OptionsPickupIndex ~= 0 then
		local pickups = Isaac.FindByType(EntityType.ENTITY_PICKUP)
		for _, entity in ipairs(pickups) do
			if
				entity:ToPickup().OptionsPickupIndex == pickup.OptionsPickupIndex
				and (entity.Index ~= pickup.Index or entity.InitSeed ~= pickup.InitSeed)
			then
				Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, entity.Position, Vector.Zero, nil)
				entity:Remove()
			end
		end
	end
	return nil
end

---@param enemy Entity
---@param allEnemies boolean?
---@param ignoreFires boolean?
---@param ignoreDummy boolean?
---@return boolean
function Helpers.IsEnemy(enemy, allEnemies, ignoreFires, ignoreDummy)
	allEnemies = allEnemies or false
	ignoreFires = ignoreFires or false
	ignoreDummy = ignoreDummy or false
	return enemy
		and (
			(enemy:IsVulnerableEnemy() or allEnemies)
				and (enemy:IsActiveEnemy() or enemy.Type == EntityType.ENTITY_FIREPLACE and enemy.Variant ~= 4 and not ignoreFires)
				and enemy:IsEnemy()
				and not EntityRef(enemy).IsFriendly
			or (enemy.Type == EntityType.ENTITY_DUMMY and not ignoreDummy)
		)
end

---@param allEnemies boolean | nil
---@param noBosses boolean | nil
---@param ignoreFires boolean | nil
---@param ignoreDummy boolean | nil
---@param includeTurrets boolean | nil
---@return EntityNPC[]
function Helpers.GetEnemies(allEnemies, noBosses, ignoreFires, ignoreDummy, includeTurrets)
	return Helpers.GetEnemiesInRadius(
		EdithRestored.Room():GetCenterPos(),
		99999,
		allEnemies,
		noBosses,
		ignoreFires,
		ignoreDummy,
		includeTurrets
	)
end

---@param position Vector
---@param radius number?
---@param allEnemies boolean | nil
---@param noBosses boolean | nil
---@param ignoreFires boolean | nil
---@param ignoreDummy boolean | nil
---@param includeTurrets boolean | nil
---@return EntityNPC?
function Helpers.GetNearestEnemy(position, radius, allEnemies, noBosses, ignoreFires, ignoreDummy, includeTurrets)
	local enemies = type(radius) ~= "number"
			and Helpers.GetEnemies(allEnemies, noBosses, ignoreFires, ignoreDummy, includeTurrets)
		or Helpers.GetEnemiesInRadius(position, radius, allEnemies, noBosses, ignoreFires, ignoreDummy, includeTurrets)

	local closest = nil
	for _, enemy in ipairs(enemies) do
		if closest == nil or position:Distance(closest.Position) > position:Distance(enemy.Position) then
			closest = enemy
		end
	end
	return closest
end

---@param position Vector
---@param radius number
---@param allEnemies boolean | nil
---@param noBosses boolean | nil
---@param ignoreFires boolean | nil
---@param ignoreDummy boolean | nil
---@param includeTurrets boolean | nil
---@return EntityNPC[]
function Helpers.GetEnemiesInRadius(position, radius, allEnemies, noBosses, ignoreFires, ignoreDummy, includeTurrets)
	local cap = Capsule(position, position, radius)
	local enemies = {}
	for _, enemy in ipairs(Isaac.FindInCapsule(cap, EntityPartition.ENEMY)) do
		if Helpers.IsEnemy(enemy, allEnemies, ignoreFires, ignoreDummy) then
			if not enemy:IsBoss() or (enemy:IsBoss() and not noBosses) then
				--[[if enemy.Type == EntityType.ENTITY_ETERNALFLY then
					enemy:Morph(EntityType.ENTITY_ATTACKFLY,0,0,-1)
				end]]
				--if not (Helpers.HereticBattle(enemy) or Helpers.IsTurret(enemy) and not includeTurrets) then
				table.insert(enemies, enemy)
				--end
			end
		end
	end
	return enemies
end

---@param a number | Vector
---@param b number | Vector
---@param t number
---@param speed number
---@return number | Vector
function Helpers.Lerp(a, b, t, speed)
	speed = speed or 1
	return a + (b - a) * speed * t
end

---@param x number
---@return integer
function Helpers.Sign(x)
	return x >= 0 and 1 or -1
end

---@return boolean
function Helpers.IsMenuing()
	if ModConfigMenu and ModConfigMenu.IsVisible or DeadSeaScrollsMenu and DeadSeaScrollsMenu.OpenedMenu then
		return true
	end
	return false
end

---@return boolean
function Helpers.InBoilerMirrorWorld()
	return FFGRACE and FFGRACE:IsBoilerMirrorWorld()
end

---@return boolean
function Helpers.InMirrorWorld()
	return EdithRestored.Room():IsMirrorWorld() or Helpers.InBoilerMirrorWorld()
end

---@param player EntityPlayer
---@param allowJump boolean?
---@return boolean
function Helpers.CanMove(player, allowJump)
	local controlsEnabled = player.ControlsEnabled

	local isDead = player:IsDead()

	local isPlayingForbiddenExtraAnimation = false
	local forbiddenExtraAnimations = {
		"Appear",
		"Death",
		"TeleportUp",
		"TeleportDown",
		"Trapdoor",
		"MinecartEnter",
		"Jump",
		"LostDeath",
		"FallIn",
		"HoleDeath",
		"JumpOut",
		"LightTravel",
		"LeapUp",
		"SuperLeapUp",
		"LeapDown",
		"SuperLeapDown",
		"ForgottenDeath",
		"DeathTeleport",
		"EdithJump",
		"EdithJumpQuick",
		"EdithJumpBigUp",
		"EdithJumpBigDown",
	}
	local playerSpr = player:GetSprite()
	for _, anim in ipairs(forbiddenExtraAnimations) do
		if playerSpr:IsPlaying(anim) and (anim ~= "Jump" or anim == "Jump" and not allowJump) then
			isPlayingForbiddenExtraAnimation = true
			break
		end
	end

	return controlsEnabled and not isDead and not isPlayingForbiddenExtraAnimation
end

---@param player EntityPlayer
---@return boolean
function Helpers.CantMove(player)
	return not (
		player:GetEffects():HasCollectibleEffect(CollectibleType.COLLECTIBLE_MEGA_MUSH)
		or player:IsCoopGhost()
		or player:HasCurseMistEffect()
	)
end

---@param player EntityPlayer
---@param type PlayerType | integer
---@return boolean
function Helpers.IsPlayerType(player, type)
	return player:GetPlayerType() == type
end

---@param player EntityPlayer
---@return number
function Helpers.GetPlayerIndex(player)
	local id = 1
	if player:GetPlayerType() == PlayerType.PLAYER_LAZARUS2_B then
		id = 2
	end
	return player:GetCollectibleRNG(id):GetSeed()
end

---@param bomb EntityBomb
---@return number
function Helpers.GetBombExplosionRadius(bomb)
	local damage = bomb.ExplosionDamage
	local radiusMult = bomb.RadiusMultiplier
	local radius

	if damage >= 175.0 then
		radius = 105.0
	else
		if damage <= 140.0 then
			radius = 75.0
		else
			radius = 90.0
		end
	end

	return radius * radiusMult
end

---@param damage number
---@param isBomber boolean?
---@return number
function Helpers.GetBombRadiusFromDamage(damage, isBomber)
	if 300 <= damage then
		return 300.0
	elseif isBomber then
		return 155.0
	elseif 175.0 <= damage then
		return 105.0
	else
		if damage <= 140.0 then
			return 75.0
		else
			return 90.0
		end
	end
end

---@param player EntityPlayer
---@param includeNormal boolean?
---@param includeTainted boolean?
---@return boolean
function Helpers.IsPlayerEdith(player, includeNormal, includeTainted)
	if includeNormal == nil then
		includeNormal = true
	end
	if includeTainted == nil then
		includeTainted = true
	end
	if
		player
		and (
			(Helpers.IsPlayerType(player, EdithRestored.Enums.PlayerType.EDITH) and includeNormal)
			or Helpers.IsPlayerType(player, EdithRestored.Enums.PlayerType.EDITH_B) and includeTainted
		)
	then
		return true
	end
	return false
end


---@param player EntityPlayer
---@return boolean
function Helpers.IsPureEdith(player)
	return Helpers.IsPlayerEdith(player, true, false)
end

---@param player EntityPlayer
---@return boolean
function Helpers.IsTaintedEdith(player)
	return Helpers.IsPlayerEdith(player, false, true)
end

--self explanatory
---@param player EntityPlayer
---@param slot ActiveSlot | integer?
---@return integer
function Helpers.GetCharge(player, slot)
	return player:GetActiveCharge(slot) + player:GetBatteryCharge(slot)
end

---@param player EntityPlayer
---@return integer
function Helpers.BatteryChargeMult(player)
	return player:HasCollectible(CollectibleType.COLLECTIBLE_BATTERY) and 2 or 1
end

---@param player EntityPlayer
---@return Vector
function Helpers.GetMovementActionVector(player)
	local down = Input.GetActionValue(ButtonAction.ACTION_DOWN, player.ControllerIndex)
	local up = Input.GetActionValue(ButtonAction.ACTION_UP, player.ControllerIndex)
	local left = Input.GetActionValue(ButtonAction.ACTION_LEFT, player.ControllerIndex)
	local right = Input.GetActionValue(ButtonAction.ACTION_RIGHT, player.ControllerIndex)

	return Vector(right - left, down - up):Normalized()
end

---@param player EntityPlayer
---@param slot ActiveSlot | integer?
---@return ActiveSlot?
function Helpers.GetUnchargedSlot(player, slot)
	local charge = Helpers.GetCharge(player, slot)
	local battery = Helpers.BatteryChargeMult(player)
	local item = itemConfig:GetCollectible(player:GetActiveItem(slot))
	if player:GetActiveItem(slot) == CollectibleType.COLLECTIBLE_ALABASTER_BOX then
		if charge < item.MaxCharges then
			return slot
		end
	elseif
		player:GetActiveItem(slot) > 0
		and charge < item.MaxCharges * battery
		and player:GetActiveItem(slot) ~= CollectibleType.COLLECTIBLE_ERASER
	then
		return slot
	elseif slot < ActiveSlot.SLOT_POCKET then
		slot = Helpers.GetUnchargedSlot(player, slot + 1)
		return slot
	end
	return nil
end

---@param player EntityPlayer
---@param slot ActiveSlot | integer?
---@param item unknown?
function Helpers.OverCharge(player, slot, item)
	local effect = Isaac.Spawn(1000, 49, 1, player.Position + Vector(0, 1), Vector.Zero, nil)
	effect:GetSprite().Offset = Vector(0, -22)
end

---@param _vec Vector
---@return integer | Direction
function Helpers.VecToDir(_vec)
	local angle = _vec:GetAngleDegrees()
	if angle < 45 and angle >= -45 then
		return Direction.RIGHT
	elseif angle < -45 and angle >= -135 then
		return Direction.UP
	elseif angle > 45 and angle <= 135 then
		return Direction.DOWN
	end
	return Direction.LEFT
end

---@param player EntityPlayer
---@return boolean
function Helpers.IsEdithNearEnemy(player) -- Enemy detection
	local data = EdithRestored:RunSave(player)
	for _, enemies in pairs(Isaac.FindInRadius(player.Position, 95)) do
		if
			enemies:IsVulnerableEnemy()
			and enemies:IsActiveEnemy()
			and data.Pepper < 5
			and EntityRef(enemies).IsCharmed == false
		then
			return true
		end
	end
	return false
end

---@param player EntityPlayer
---@param amount integer?
function Helpers.ChangePepperValue(player, amount)
	amount = amount or 0
	local data = EdithRestored:RunSave(player)
	if not data.Pepper then
		data.Pepper = 0
	end
	data.Pepper = math.max(0, math.min(5, data.Pepper + amount))
end

---@param player EntityPlayer
---@param sprite string
function Helpers.ChangeHoodSprite(player, sprite)
	player:ReplaceCostumeSprite(itemConfig:GetNullItem(EdithRestored.Enums.Costumes.EDITH_HOOD), sprite, 5)
end

---@param player EntityPlayer
---@param loading boolean?
function Helpers.ChangeSprite(player, loading)
	local data = EdithRestored:RunSave(player)
	local sprite = player:GetSprite()
	if Helpers.IsPureEdith(player) then
		if sprite:GetFilename() ~= EdithRestored.Enums.PlayerSprites.EDITH and not player:IsCoopGhost() then
			sprite:Load(EdithRestored.Enums.PlayerSprites.EDITH, true)
		end
	elseif Helpers.IsTaintedEdith(player) then
		-- TODO code new logic when done
	elseif
		sprite:GetFilename() == EdithRestored.Enums.PlayerSprites.EDITH
		or sprite:GetFilename() == EdithRestored.Enums.PlayerSprites.EDITH_B
	then
		sprite:Load("gfx/001.000_Player.anm2", true)
		sprite:Update()
	end
end

---@param player EntityPlayer
---@return boolean
function Helpers.magicchalk_3f(player)
	local magicchalk = Isaac.GetItemIdByName("Magic Chalk")
	return magicchalk ~= -1 and player:HasCollectible(magicchalk)
end

---@param list table
---@return table
function Helpers.Shuffle(list)
	local size, shuffled = #list, list
	for i = size, 2, -1 do
		local j = math.random(i)
		shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
	end
	return shuffled
end

---@return integer
function Helpers.GetMaxCollectibleID()
	return EdithRestored.ItemConfig:GetCollectibles().Size - 1
end

---@return integer
function Helpers.GetMaxTrinketID()
	return EdithRestored.ItemConfig:GetTrinkets().Size - 1
end

---@param firedelay number
---@param val number
---@return number
function Helpers.tearsUp(firedelay, val)
	local currentTears = Helpers.ToTearsPerSecond(firedelay)
	local newTears = currentTears + val
	return math.max((30 / newTears) - 1, -0.75)
end

---@param player EntityPlayer
---@return number
function Helpers.GetTrueRange(player)
	return player.TearRange / 40.0
end

---@param range number
---@param val number
---@return number
function Helpers.rangeUp(range, val)
	local currentRange = range / 40.0
	local newRange = currentRange + val
	return math.max(1.0, newRange) * 40.0
end

---@param player EntityPlayer
---@param includeTearDrop boolean?
---@return number
function Helpers.GetLuck(player, includeTearDrop)
	local tearDropLuck = 0
	if includeTearDrop then
		tearDropLuck = player:GetTrinketMultiplier(TrinketType.TRINKET_TEARDROP_CHARM) * 2
		if tearDropLuck > 0 then
			tearDropLuck = tearDropLuck + 2
		end
	end
	return player.Luck + tearDropLuck
end

---@param sound SoundEffect | integer
---@param alwaysSfx boolean?
function Helpers.PlaySND(sound, alwaysSfx)
	if
		Options.AnnouncerVoiceMode == 2
		or Options.AnnouncerVoiceMode == 0 and TSIL.Random.GetRandomInt(0, 3) == 0
		or alwaysSfx
	then
		sfx:Play(sound, 1, 0)
	end
end

---@param pos Vector
---@return Vector
function Helpers.GridAlignPosition(pos)
	local x = pos.X
	local y = pos.Y

	x = 40 * math.floor(x / 40 + 0.5)
	y = 40 * math.floor(y / 40 + 0.5)

	return Vector(x, y)
end

---@param enemy Entity
---@return boolean
function Helpers.IsTargetableEnemy(enemy)
	return enemy:IsEnemy()
		and enemy:IsVulnerableEnemy()
		and enemy:IsActiveEnemy()
		and not (
			enemy:IsBoss()
			or enemy.Type == EntityType.ENTITY_FIREPLACE
			or (enemy.Type == EntityType.ENTITY_EVIS and enemy.Variant == 10)
		)
end

---@param player EntityPlayer
---@return boolean
function Helpers.DoesPlayerHaveRightAmountOfPickups(player)
	local has7Coins = player:GetNumCoins() % 10 == 7
	local has7Keys = player:GetNumKeys() % 10 == 7
	local has7Bombs = player:GetNumBombs() % 10 == 7
	local has7Poops = player:GetPoopMana() % 10 == 7

	return has7Bombs or has7Coins or has7Keys or has7Poops
end

---@param v1 Vector
---@param v2 Vector
---@return number
local function ScalarProduct(v1, v2)
	return v1.X * v2.X + v1.Y * v2.Y
end

---@param laser EntityLaser
---@param entity Entity
---@return boolean?
function Helpers.DoesLaserHitEntity(laser, entity)
	local targetSamples = {
		entity.Position,
		entity.Position + Vector(entity.Size * entity.SizeMulti.X, 0),
		entity.Position + Vector(-entity.Size * entity.SizeMulti.X, 0),
		entity.Position + Vector(0, entity.Size * entity.SizeMulti.Y),
		entity.Position + Vector(0, -entity.Size * entity.SizeMulti.Y),
	}
	---@type VectorList
	---@diagnostic disable-next-line: assign-type-mismatch
	local samplePoints = laser:GetSamples()
	local laserSize = laser.Size

	--From https://math.stackexchange.com/questions/190111/how-to-check-if-a-point-is-inside-a-rectangle
	for i = 0, samplePoints.Size - 2, 1 do
		local point1 = samplePoints:Get(i)
		local point2 = samplePoints:Get(i + 1)

		local side = (point1 - point2):Rotated(90):Resized(laserSize)

		local cornerA = point1 + side
		local cornerB = point2 + side
		local cornerD = point1 - side

		for _, targetPos in ipairs(targetSamples) do
			local AM = targetPos - cornerA
			local AB = cornerB - cornerA
			local AD = cornerD - cornerA

			local AMpAB = ScalarProduct(AM, AB)
			local ABpAB = ScalarProduct(AB, AB)
			local AMpAD = ScalarProduct(AM, AD)
			local ADpAD = ScalarProduct(AD, AD)

			if 0 < AMpAB and AMpAB < ABpAB and 0 < AMpAD and AMpAD < ADpAD then
				return true
			end
		end
	end
end

-----------------------------------
--Helper Functions (thanks piber)--
-----------------------------------

---@param ignoreCoopBabies boolean?
---@return EntityPlayer[]
function Helpers.GetPlayers(ignoreCoopBabies)
	return Helpers.Filter(PlayerManager.GetPlayers(), function(_, player)
		return player.Variant == 0 or ignoreCoopBabies == false
	end)
end

---@param tear EntityTear | EntityLaser | EntityKnife | EntityBomb
---@return EntityPlayer?
function Helpers.GetPlayerFromTear(tear)
	for i = 1, 2 do
		local check = nil
		if i == 1 then
			check = tear.Parent
		elseif i == 2 then
			check = tear.SpawnerEntity
		end
		if check then
			if check.Type == EntityType.ENTITY_PLAYER then
				return Helpers.GetPtrHashEntity(check):ToPlayer()
			elseif check.Type == EntityType.ENTITY_FAMILIAR and check.Variant == FamiliarVariant.INCUBUS then
				local data = EdithRestored:GetData(tear)
				data.IsIncubusTear = true
				return check:ToFamiliar().Player:ToPlayer()
			end
		end
	end
	return nil
end

---@param entity Entity | EntityRef
---@return Entity?
function Helpers.GetPtrHashEntity(entity)
	if entity then
		if entity.Entity then
			entity = entity.Entity
		end
		for _, matchEntity in pairs(Isaac.FindByType(entity.Type, entity.Variant, entity.SubType, false, false)) do
			if GetPtrHash(entity) == GetPtrHash(matchEntity) then
				return matchEntity
			end
		end
	end
	return nil
end

---@param list table
---@param x any
---@return boolean
function Helpers.Contains(list, x)
	for _, v in pairs(list) do
		if v == x then
			return true
		end
	end
	return false
end

--ripairs stuff from revel
function ripairs_it(t, i)
	i = i - 1
	local v = t[i]
	if v == nil then
		return v
	end
	return i, v
end
function ripairs(t)
	return ripairs_it, t, #t + 1
end

--- Executes a function for each key-value pair of a table
---@param toIterate table
---@param funct function
function Helpers.ForEach(toIterate, funct)
	for index, value in pairs(toIterate) do
		funct(index, value)
	end
end

--filters a table given a predicate
---@param toFilter table
---@param predicate function
---@return table
function Helpers.Filter(toFilter, predicate)
	local filtered = {}

	for index, value in pairs(toFilter) do
		if predicate(index, value) then
			filtered[#filtered + 1] = value
		end
	end

	return filtered
end

--returns a list of all players that have a certain item
---@param collectibleId CollectibleType | integer
---@return EntityPlayer[]
function Helpers.GetPlayersByCollectible(collectibleId)
	local players = Helpers.GetPlayers()

	return Helpers.Filter(players, function(_, player)
		return player:HasCollectible(collectibleId)
	end)
end

--returns a list of all players that have a certain item effect (useful for actives)
---@param collectibleId CollectibleType | integer
---@return EntityPlayer[]
function Helpers.GetPlayersWithCollectibleEffect(collectibleId)
	local players = Helpers.GetPlayers()

	return Helpers.Filter(players, function(_, player)
		return player:GetEffects():HasCollectibleEffect(collectibleId)
	end)
end

--returns a list of all players that have a certain item effect (useful for actives)
---@param nullItemId NullItemID | integer
---@return EntityPlayer[]
function Helpers.GetPlayersByNullEffect(nullItemId)
	local players = Helpers.GetPlayers()

	return Helpers.Filter(players, function(_, player)
		return player:GetEffects():HasNullEffect(nullItemId)
	end)
end

--returns a list of all players of certain type
---@param playerType PlayerType | integer
---@return EntityPlayer[]
function Helpers.GetPlayersByType(playerType)
	local players = Helpers.GetPlayers()
	if not playerType or type(playerType) ~= "number" or playerType < 0 then
		return players
	end

	return Helpers.Filter(players, function(_, player)
		return player:GetPlayerType() == playerType
	end)
end

---@param achievement Achievement | integer
---@param force boolean?
function Helpers.UnlockAchievement(achievement, force) -- from Community Remix
	if not force then
		if not game:AchievementUnlocksDisallowed() then
			if not Isaac.GetPersistentGameData():Unlocked(achievement) then
				Isaac.GetPersistentGameData():TryUnlock(achievement)
			end
		end
	else
		Isaac.GetPersistentGameData():TryUnlock(achievement)
	end
end

---@param isGigaBomb boolean
---@return integer
local function GetBombDamage(isGigaBomb)
	return isGigaBomb and 300 or 100
end

---@param player EntityPlayer
---@return boolean
function Helpers.HasBombs(player)
	return player:GetNumBombs() > 0 or player:HasGoldenBomb()
end

---@param default boolean?
---@return number
function Helpers.GetStompRadius(default)
	default = type(default) == "boolean" and default or false
	return (EdithRestored.DebugMode and not default) and EdithRestored:GetDebugValue("StompRadius") or 65 --[[@as number]]
end

---@param default boolean?
---@return number
function Helpers.GetJumpHeight(default)
	default = type(default) == "boolean" and default or false
	return (EdithRestored.DebugMode and not default) and EdithRestored:GetDebugValue("JumpHeight") or 4 --[[@as number]]
end

---@param default boolean?
---@return number
function Helpers.GetJumpGravity(default)
	default = type(default) == "boolean" and default or false
	return (EdithRestored.DebugMode and not default) and EdithRestored:GetDebugValue("Gravity") or 0.7 --[[@as number]]
end

---@param player EntityPlayer
function Helpers.SpawnEdithTarget(player)
	if Helpers.GetEdithTarget(player) == nil and Helpers.IsPureEdith(player) then
		local data = EdithRestored:GetData(player)
		local TargetColor = EdithRestored:GetDefaultFileSave("TargetColor")
		data.EdithJumpTarget = Isaac.Spawn(
			1000,
			EdithRestored.Enums.Entities.EDITH_TARGET.Variant,
			0,
			player.Position,
			Vector(0, 0),
			player
		):ToEffect()
		data.EdithJumpTarget.Parent = player
		data.EdithJumpTarget.SpawnerEntity = player
		data.EdithJumpTarget.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
		data.EdithJumpTarget:GetSprite():Play("Blink", true)

		-- target.Color = Color(1, 1, 1, 0, 0, 0, 0)
		if TargetColor then
			data.EdithJumpTarget.Color =
				Color(TargetColor.R / 255, TargetColor.G / 255, TargetColor.B / 255, 1, 0, 0, 0)
		else
			data.EdithJumpTarget.Color = Color(155 / 255, 0, 0, 1, 0, 0, 0)
		end
	end
end

---@param player EntityPlayer
---@return EntityEffect?
function Helpers.GetEdithTarget(player)
	local data = EdithRestored:GetData(player)
	return data.EdithJumpTarget
end

---@param player EntityPlayer
function Helpers.RemoveEdithTarget(player)
	local data = EdithRestored:GetData(player)
	if data.EdithJumpTarget then
		data.EdithJumpTarget:Remove()
		data.EdithJumpTarget = nil
	end
end

---@param value any
---@param tab table
---@return boolean
local function InTable(value, tab)
	if type(tab) ~= "table" then
		return false
	end
	for _, v in pairs(tab) do
		if v == value then
			return true
		end
	end
	return false
end

---@param player EntityPlayer
---@param pickerItem WeightedOutcomePicker
---@param pickerTrinket WeightedOutcomePicker
---@param col_trink CollectibleType | TrinketType | integer
---@param isItem boolean
---@param chance number
---@param limit number?
---@return table
local function FillWithRandomItemsTrinkets(player, pickerItem, pickerTrinket, col_trink, isItem, chance, limit)
	local rng
	local hasItem = false
	if col_trink > 0 then
		if isItem then
			if col_trink <= (Helpers.GetMaxCollectibleID()) then
				rng = player:GetCollectibleRNG(col_trink)
				hasItem = player:HasCollectible(col_trink)
			end
		else
			if col_trink <= (Helpers.GetMaxTrinketID()) then
				rng = player:GetTrinketRNG(col_trink)
				hasItem = player:HasTrinket(col_trink)
			end
		end
	end
	local outputTable = { Items = {}, Trinkets = {} }
	while
		hasItem
		and (pickerItem:GetNumOutcomes() > 0 or pickerTrinket:GetNumOutcomes() > 0)
		and (limit == nil or (#outputTable.Items + #outputTable.Trinkets) < limit)
	do
		if pickerItem:GetNumOutcomes() > 0 and (rng:RandomInt(2) == 0 or pickerTrinket:GetNumOutcomes() == 0) then
			local outcome = pickerItem:PickOutcome(rng)
			if rng:RandomFloat() <= chance then
				outputTable.Items[#outputTable.Items + 1] = outcome
			end
			pickerItem:RemoveOutcome(outcome)
		elseif pickerTrinket:GetNumOutcomes() > 0 then
			local outcome = pickerTrinket:PickOutcome(rng)
			if rng:RandomFloat() <= chance then
				outputTable.Trinkets[#outputTable.Trinkets + 1] = outcome
			end
			pickerTrinket:RemoveOutcome(outcome)
		end
	end
	return outputTable
end

---@param player EntityPlayer
---@param callbacks table
---@return table
local function GetCallbacksPools(player, callbacks)
	local pools = {}
	for pool, valPool in pairs(stompPoolsList) do
		for id, valItem in pairs(valPool) do
			local itemsPicker = WeightedOutcomePicker()
			local trinketsPicker = WeightedOutcomePicker()
			local poolItemsPicker = Helpers.Filter(
				Helpers.MergeTables({}, table.unpack(callbacks)),
				function(index, callback)
					return type(callback.Param) == "table"
						and type(callback.Param.Item) == "number"
						and type(callback.Param[valItem.Name]) == "boolean"
						and callback.Param[valItem.Name] == true
				end
			)
			local poolTrinketsPicker = Helpers.Filter(
				Helpers.MergeTables({}, table.unpack(callbacks)),
				function(index, callback)
					return type(callback.Param) == "table"
						and type(callback.Param.Trinket) == "number"
						and type(callback.Param[valItem.Name]) == "boolean"
						and callback.Param[valItem.Name] == true
				end
			)

			for _, item in ipairs(poolItemsPicker) do
				itemsPicker:AddOutcomeFloat(item.Param.Item, 1 / #poolItemsPicker)
			end

			for _, item in ipairs(poolTrinketsPicker) do
				trinketsPicker:AddOutcomeFloat(item.Param.Trinket, 1 / #poolTrinketsPicker)
			end

			pools[valItem.Name] = FillWithRandomItemsTrinkets(
				player,
				itemsPicker,
				trinketsPicker,
				id,
				pool == "Items",
				valItem.Chance,
				valItem.Limit
			)
		end
	end
	return pools
end

---@param player EntityPlayer
---@param multiplier number
---@param force boolean?
---@param doBombStomp boolean?
---@param triggerStompCallbacks boolean?
---@param doParticles {Tooth: boolean?, Splash: boolean?}?
function Helpers.Stomp(player, multiplier, force, doBombStomp, triggerStompCallbacks, doParticles)
	local data = EdithRestored:GetData(player)
	local pData = EdithRestored:RunSave(player)
	local room = EdithRestored.Room()
	local bdType = room:GetBackdropType()
	local chap4 = (
		bdType == 10
		or bdType == 11
		or bdType == 12
		or bdType == 13
		or bdType == 34
		or bdType == 43
		or bdType == 44
	)
	local level = EdithRestored.Level:GetStage()

	local stompDamage = (1 + (level * 6 / 1.4) + player.Damage * 2.5) * Helpers.Clamp(multiplier, 0.1, multiplier)
	local bombDamage = 0
	local radius = Helpers.GetStompRadius()
	local knockback = 15

	-- yeah the en of that stuff
	local bombs = player:GetNumBombs()
	local isGigaBomb = false
	if doBombStomp ~= false and doBombStomp ~= nil then
		if data.BombStomp ~= nil or force then
			if Helpers.HasBombs(player) or force then
				-- Check if edith has a golden bomb cause well using a golden bomb doesn't substract your bomb count
				if player:GetNumGigaBombs() > 0 then
					isGigaBomb = true
				end
				if not force then
					if player:GetNumGigaBombs() > 0 then
						player:AddGigaBombs(-1)
					elseif not player:HasGoldenBomb() then
						player:AddBombs(-1)
					end
				end

				bombDamage = GetBombDamage(isGigaBomb)
			end
		end
		if doBombStomp == nil then
			doBombStomp = force or data.BombStomp
		end
	end
	local breakRocks = false
	local knockbackTime = 5
	local knockbackDamage = false

	pData.StompCount = pData.StompCount and ((pData.StompCount + 1) % 2) or 1

	local hasBombs = bombs > 0 or force
	local stompPosition = player.Position
	local doProptosis = false

	if triggerStompCallbacks == true then
		local stompCallbacks = Isaac.GetCallbacks(EdithRestored.Enums.Callbacks.ON_EDITH_STOMP)
		local stompModifyCallback = Isaac.GetCallbacks(EdithRestored.Enums.Callbacks.ON_EDITH_MODIFY_STOMP)

		local pools = GetCallbacksPools(player, { stompCallbacks, stompModifyCallback })

		local forcedStompCallbacks = { Items = {}, Trinkets = {} }
		--#region Damage, knockback, knockback time, damage on knockback, radius, breaking rocks, stomp forcing modifications
		for _, callback in ipairs(stompModifyCallback) do
			local params = callback.Param
			local isTbl = type(params) == "table"
			local item = (isTbl and type(params.Item) == "number") and params.Item
			local trinket = (isTbl and type(params.Trinket) == "number") and params.Trinket
			local isStompPool = {}
			for name, tab in pairs(pools) do
				isStompPool[name] = isTbl
					and (
						InTable(item, tab.Items) and not player:HasCollectible(item)
						or InTable(trinket, tab.Trinkets) and not player:HasTrinket(trinket)
					)
			end

			if
				params == nil
				or item == nil and trinket == nil
				or type(item) == "number" and player:HasCollectible(item)
				or type(trinket) == "number" and player:HasTrinket(trinket)
				or InTable(true, isStompPool)
			then
				local ret = callback.Function(
					EdithRestored,
					player,
					stompDamage,
					radius,
					knockback,
					doBombStomp or bombDamage > 0,
					isStompPool
				)
				if type(ret) == "table" then
					stompDamage = type(ret.StompDamage) == "number" and ret.StompDamage or stompDamage
					knockback = type(ret.Knockback) == "number" and ret.Knockback or knockback
					radius = type(ret.Radius) == "number" and ret.Radius or radius
					if type(ret.BreakRocks) == "boolean" and ret.BreakRocks == true then
						breakRocks = true
					end
					if type(ret.KnockbackTime) == "number" and ret.KnockbackTime > 0 then
						knockbackTime = ret.KnockbackTime
					end
					if type(ret.KnockbackDamage) == "boolean" and ret.KnockbackDamage == true then
						knockbackDamage = ret.KnockbackDamage
					end
					if type(ret.DoStomp) == "boolean" and ret.DoStomp == true then
						if item ~= nil then
							forcedStompCallbacks.Items[item] = true
						end
						if trinket ~= nil then
							forcedStompCallbacks.Trinkets[trinket] = true
						end
					end
					if type(ret.DoProptosis) == "boolean" then
						doProptosis = doProptosis or ret.DoProptosis
					end
				end
			end
		end

		if
			Helpers.IsPureEdith(player)
			and player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT)
		then
			knockback = knockback * 2
		end

		for _, callback in ipairs(stompCallbacks) do
			local params = callback.Param
			local isTbl = type(params) == "table"
			local item = (isTbl and type(params.Item) == "number") and params.Item
			local trinket = (isTbl and type(params.Trinket) == "number") and params.Trinket
			local isStompPool = {}
			for name, tab in pairs(pools) do
				isStompPool[name] = isTbl
					and (
						InTable(item, tab.Items) and not player:HasCollectible(item)
						or InTable(trinket, tab.Trinkets) and not player:HasTrinket(trinket)
					)
			end
			if
				params == nil
				or item == nil and trinket == nil
				or type(item) == "number" and (player:HasCollectible(item) or forcedStompCallbacks.Items[item])
				or type(trinket) == "number" and (player:HasTrinket(trinket) or forcedStompCallbacks.Trinkets[trinket])
				or InTable(true, isStompPool)
			then
				callback.Function(
					EdithRestored,
					player,
					stompDamage,
					EdithRestored:GetData(player).BombStomp,
					type(item) == "number" and forcedStompCallbacks.Items[item]
						or type(trinket) == "number" and forcedStompCallbacks.Trinkets[trinket],
					isStompPool
				)
			end
		end
	end

	local enemiesInRadius = Helpers.GetEnemiesInRadius(stompPosition, radius, true)
	if not (EdithRestored.DebugMode and EdithRestored:GetDebugValue("IgnoreStompDamage")) then
		for _, enemy in pairs(enemiesInRadius) do
			enemy:AddKnockback(
				EntityRef(player),
				(enemy.Position - stompPosition):Resized(knockback),
				knockbackTime,
				Helpers.IsPureEdith(player)
						and player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT)
					or knockbackDamage
			)
			if enemy:IsActiveEnemy() and enemy:IsVulnerableEnemy() then
				local newDamage = stompDamage
				if doProptosis then
					newDamage = newDamage * (1.5 - stompPosition:Distance(enemy.Position) / radius)
				end
				EdithRestored:GetData(player).StompDamage = newDamage
				enemy:TakeDamage(
					newDamage,
					DamageFlag.DAMAGE_CRUSH | DamageFlag.DAMAGE_EXPLOSION,
					EntityRef(player),
					30
				)
			end
			if enemy.Type == EntityType.ENTITY_FIREPLACE and enemy.Variant ~= 4 then
				enemy:Die()
			end
		end

		for i = 0, room:GetGridSize() - 1 do
			local grid = room:GetGridEntity(i)
			if grid then
				if
					(breakRocks or grid:ToPoop() and grid.State ~= 1000)
					and stompPosition:Distance(grid.Position) <= radius
				then
					grid:Destroy()
				end
			end
		end
	end

	local doStompsCallbacks = Isaac.GetCallbacks(EdithRestored.Enums.Callbacks.DO_STOMP_EXPLOSION)
	local stompExplosionCallback = Isaac.GetCallbacks(EdithRestored.Enums.Callbacks.ON_EDITH_STOMP_EXPLOSION)
	local pools = GetCallbacksPools(player, { doStompsCallbacks, stompExplosionCallback })

	local bombEffectTriggered = bombDamage > 0

	if not bombEffectTriggered and doBombStomp then
		for _, callback in ipairs(doStompsCallbacks) do
			local params = callback.Param
			local isTbl = type(params) == "table"
			local item = (isTbl and type(params.Item) == "number") and params.Item
			local trinket = (isTbl and type(params.Trinket) == "number") and params.Trinket
			local isStompPool = {}
			for name, tab in pairs(pools) do
				isStompPool[name] = isTbl
					and (
						InTable(item, tab.Items) and not player:HasCollectible(item)
						or InTable(trinket, tab.Trinkets) and not player:HasTrinket(trinket)
					)
			end
			if
				params == nil
				or item == nil and trinket == nil
				or type(item) == "number" and player:HasCollectible(item)
				or type(trinket) == "number" and player:HasTrinket(trinket)
				or InTable(true, isStompPool)
			then
				local ret = callback.Function(callback.Mod, player, isStompPool)
				if ret == true then
					bombEffectTriggered = true
					bombDamage = GetBombDamage(isGigaBomb)
					break
				end
			end
		end
	end

	if isGigaBomb then
		radius = radius * 2
	end

	if bombEffectTriggered then
		for _, callback in ipairs(stompExplosionCallback) do
			local params = callback.Param
			local isTbl = type(params) == "table"
			local item = (isTbl and type(params.Item) == "number") and params.Item
			local trinket = (isTbl and type(params.Trinket) == "number") and params.Trinket
			local isStompPool = {}
			for name, tab in pairs(pools) do
				isStompPool[name] = isTbl
					and (
						InTable(item, tab.Items) and not player:HasCollectible(item)
						or InTable(trinket, tab.Trinkets) and not player:HasTrinket(trinket)
					)
			end
			if
				params == nil
				or item == nil and trinket == nil
				or type(item) == "number" and player:HasCollectible(item)
				or type(trinket) == "number" and player:HasTrinket(trinket)
				or InTable(true, isStompPool)
			then
				local ret = callback.Function(
					callback.Mod,
					player,
					bombDamage,
					stompPosition,
					radius,
					hasBombs,
					isGigaBomb,
					false
				)
				if type(ret) == "table" then
					bombDamage = ret.BombDamage or bombDamage
					radius = ret.Radius or radius
				end
			end
		end

		game:BombExplosionEffects(stompPosition, bombDamage, player:GetBombFlags(), Color.Default, player)

		if player:HasCollectible(CollectibleType.COLLECTIBLE_SCATTER_BOMBS) then
			local rng = player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_SCATTER_BOMBS)
			for i = 1, rng:RandomInt(4, 5) do
				local flags = player:GetBombFlags()
				if isGigaBomb then
					flags = flags | TearFlags.TEAR_GIGA_BOMB
				end
				Isaac.CreateTimer(function()
					local explosionPosition = Vector.FromAngle(rng:RandomInt(1, 360))
						:Resized(TSIL.Random.GetRandomFloat(0.1, radius * 1.5, rng))
					game:BombExplosionEffects(
						stompPosition + explosionPosition,
						bombDamage / 2,
						player:GetBombFlags(),
						Color.Default,
						player,
						0.5,
						true,
						false
					)
					for _, callback in ipairs(stompExplosionCallback) do
						local params = callback.Param
						local isTbl = type(params) == "table"
						local item = (isTbl and type(params.Item) == "number") and params.Item
						local trinket = (isTbl and type(params.Trinket) == "number") and params.Trinket
						local isStompPool = {}
						for name, tab in pairs(pools) do
							isStompPool[name] = isTbl
								and (
									InTable(item, tab.Items) and not player:HasCollectible(item)
									or InTable(trinket, tab.Trinkets) and not player:HasTrinket(trinket)
								)
						end
						if
							params == nil
							or item == nil and trinket == nil
							or type(item) == "number" and player:HasCollectible(item)
							or type(trinket) == "number" and player:HasTrinket(trinket)
							or InTable(true, isStompPool)
						then
							callback.Function(
								callback.Mod,
								player,
								bombDamage / 2,
								stompPosition + explosionPosition,
								radius / 2,
								hasBombs,
								isGigaBomb,
								true
							)
						end
					end
				end, rng:RandomInt(5, 10), 1, false)
			end
		end

		if player:GetTrinketMultiplier(TrinketType.TRINKET_RING_CAP) > 0 then
			for i = 1, player:GetTrinketMultiplier(TrinketType.TRINKET_RING_CAP) do
				local rng = player:GetTrinketRNG(TrinketType.TRINKET_RING_CAP)
				game:BombExplosionEffects(
					stompPosition + Vector.FromAngle(rng:RandomInt(1, 360)):Resized(rng:RandomInt(100) * 0.015),
					bombDamage,
					player:GetBombFlags(),
					Color.Default,
					player
				)
			end
		end
	end
	--#endregion

	game:ShakeScreen(10)

	local sound = chap4 and SoundEffect.SOUND_MEATY_DEATHS or SoundEffect.SOUND_STONE_IMPACT
	sfx:Play(sound, 1, 0)

	if doParticles and doParticles.Tooth then
		for i = 1, TSIL.Random.GetRandomInt(6, 9) do
			local randRockVel = Vector(TSIL.Random.GetRandomInt(-3, 3), TSIL.Random.GetRandomInt(-3, 3))
			Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.TOOTH_PARTICLE, 1, stompPosition, randRockVel, nil)
		end
	end
	if not doParticles or not doParticles.Splash then
		if room:HasWater() then
			-- if not chap4 then
			local splashpitch = 0.9 + (TSIL.Random.GetRandomFloat(0, 1) / 10)
			local waterSplash = Isaac.Spawn(
				EntityType.ENTITY_EFFECT,
				EffectVariant.BIG_SPLASH,
				0,
				stompPosition + Vector(0, 2),
				Vector.Zero,
				player
			):ToEffect()
			waterSplash.SpriteScale = waterSplash.SpriteScale * 0.65
			sfx:Play(EdithRestored.Enums.SFX.Edith.WATER_STOMP, 1, 0, false, splashpitch, 0)
			-- end
		else
			local poof
			if not chap4 then
				poof =
					Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 1, stompPosition, Vector.Zero, player)
						:ToEffect()
			else
				poof = Isaac.Spawn(1000, 16, 3, stompPosition, Vector.Zero, nil):ToEffect()
				if bdType == 13 then
					poof.Color = Color(0, 0, 0, 1, 0.3, 0.4, 0.6)
				elseif bdType == 34 then
					poof.Color = Color(0, 0, 0, 1, 0.62, 0.65, 0.62)
				elseif bdType == 43 then
					poof.Color = Color(0, 0, 0, 1, 0.55, 0.57, 0.55)
				end
			end
			poof.SpriteScale = poof.SpriteScale * 0.5
			poof:GetSprite().PlaybackSpeed = 2
		end
	end
end

---@param x number
---@return number
function Helpers.EaseOutBack(x)
	local c1 = 1.70158
	local c3 = c1 + 1

	return 1 + c3 * (x - 1) ^ 3 + c1 * (x - 1) ^ 2
end

---@param player EntityPlayer
---@return boolean
function Helpers.IsPlayingExtraAnimation(player)
	local sprite = player:GetSprite()
	local anim = sprite:GetAnimation()

	local normalAnims = {
		["WalkUp"] = true,
		["WalkDown"] = true,
		["WalkLeft"] = true,
		["WalkRight"] = true,
	}

	return not normalAnims[anim]
end

---@param num number
---@param dp integer
---@return number
function Helpers.Round(num, dp)
	local mult = 10 ^ (dp or 0)
	return math.floor(num * mult + 0.5) / mult
end

---By catinsurance
---@param maxFireDelay number
---@return number
function Helpers.ToTearsPerSecond(maxFireDelay)
	return 30 / (maxFireDelay + 1)
end

---By catinsurance
---@param tearsPerSecond number
---@return number
function Helpers.ToMaxFireDelay(tearsPerSecond)
	return (30 / tearsPerSecond) - 1
end

---@param ... table[]
---@return table
function Helpers.MergeTables(...)
	local tables = { ... }
	local t = tables[1]
	table.remove(tables, 1)
	for i, tab in ipairs(tables) do
		for _, v in pairs(tab) do
			table.insert(t, v)
		end
	end
	return t
end

---@param ... table[]
---@return table
function Helpers.MergeiTables(...)
	local tables = table.unpack(...)
	local t1 = tables[1]
	table.remove(tables, 1)
	for _, tab in ipairs(tables) do
		for _, v in ipairs(tab) do
			table.insert(t1, v)
		end
	end
	return t1
end

--#region bless Fiend Folio (you read that right)
local function runUpdates(tab) --This is from Fiend Folio
	for i = #tab, 1, -1 do
		local f = tab[i]
		f.Delay = f.Delay - 1
		if f.Delay <= 0 then
			f.Func()
			table.remove(tab, i)
		end
	end
end

local delayedFuncs = {}
---@param foo function
---@param delay number
---@param callback ModCallbacks | integer | string
function Helpers.scheduleForUpdate(foo, delay, callback)
	callback = callback or ModCallbacks.MC_POST_UPDATE
	if not delayedFuncs[callback] then
		delayedFuncs[callback] = {}
		EdithRestored:AddCallback(callback, function()
			runUpdates(delayedFuncs[callback])
		end)
	end

	table.insert(delayedFuncs[callback], { Func = foo, Delay = delay })
end
--#endregion

---@param item CollectibleType | integer
---@return boolean
function Helpers.IsItemDisabled(item)
	for _, disabledItem in ipairs(EdithRestored:GetDefaultFileSave("DisabledItems")) do
		if item == EdithRestored.Enums.CollectibleType[disabledItem] then
			return true
		end
	end
	return false
end

---@param v1 Vector
---@param v2 Vector
---@return boolean
function Helpers.VectorEquals(v1, v2)
	return v1.X == v2.X and v1.Y == v2.Y
end

---@param value number
---@param min number
---@param max number
---@return number
function Helpers.Clamp(value, min, max)
	if value < min then
		return min
	elseif value > max then
		return max
	else
		return value
	end
end

---@param id CollectibleType | TrinketType | integer
---@param isCollectible boolean
---@param name string
---@param limit integer?
---@param chance number?
function Helpers.AddStompPool(id, isCollectible, name, limit, chance)
	limit = type(limit) == "number" and limit or 3
	chance = type(chance) == "number" and chance or 0.25
	if type(id) == "number" and type(isCollectible) == "boolean" and type(name) == "string" then
		if isCollectible then
			stompPoolsList.Items[id] = { Name = name, Limit = limit, Chance = chance }
		else
			stompPoolsList.Trinkets[id] = { Name = name, Limit = limit, Chance = chance }
		end
	end
end

---@param id number | string
function Helpers.IsChallenge(id)
	if type(id) ~= "number" and type(id) ~= "string" then
		return false
	end
	if type(id) == "string" then
		id = Isaac.GetChallengeIdByName(id)
	end
	return Isaac.GetChallenge() == id
end

---@param trinketID TrinketType | integer
function Helpers.AddTrinketToPool(trinketID)
	local trinketsNotInPool = {}
	local trinketsSize = Helpers.GetMaxTrinketID()
	for i = 1, trinketsSize do
		if i ~= trinketID then
			local trinketConf = itemConfig:GetTrinket(i)
			if trinketConf and trinketConf:IsTrinket() then
				if not itemPool:HasTrinket(i) then
					trinketsNotInPool[i] = false
				end
			end
		end
	end
	itemPool:ResetTrinkets()
	for id, notInPool in pairs(trinketsNotInPool) do
		itemPool:RemoveTrinket(id)
	end
end

---@param id NullItemID
---@return boolean
function Helpers.AnyoneHasNullItem(id)
	for _, player in ipairs(PlayerManager.GetPlayers()) do
		if player:GetEffects():HasNullEffect(id) then
			return true
		end
	end
	return false
end

EdithRestored.Helpers = Helpers

local SoulOfEdith = {}
local Helpers = EdithRestored.Helpers
local sfx = EdithRestored.SFX

local function GetRandomDoorPosition(rng)
	local doorSlots = {}
	for i = 0, DoorSlot.NUM_DOOR_SLOTS - 1 do
		if EdithRestored.Room():GetDoor(i) then
			table.insert(doorSlots, EdithRestored.Room():GetDoor(i).Position)
		end
	end
	if #doorSlots > 0 then
		return doorSlots[rng:RandomInt(#doorSlots) + 1]
	end
	return nil
end

local function GetAntiSoftLockPosition(tab, initPos, rng, canFly)
	local pathFinderNPC = Isaac.Spawn(EntityType.ENTITY_SHOPKEEPER, 0, 0, initPos, Vector.Zero, nil):ToNPC()
	pathFinderNPC:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
	pathFinderNPC.Visible = false
	pathFinderNPC.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
	pathFinderNPC.GridCollisionClass = canFly and EntityGridCollisionClass.GRIDCOLL_WALLS
		or EntityGridCollisionClass.GRIDCOLL_GROUND
	local doorPos
	local antiInfLoop = 0
	repeat
		doorPos = GetRandomDoorPosition(rng)
		local newTab =
			Helpers.Shuffle(Helpers.MergeTables(tab, { { Position = EdithRestored.Room():GetRandomPosition(20) } }))
		pathFinderNPC.Position = #tab == 1 and tab[1].Position or newTab[rng:RandomInt(1, #newTab)].Position
		antiInfLoop = antiInfLoop + 1
	until type(doorPos) ~= nil and pathFinderNPC.Pathfinder:HasPathToPos(doorPos, false) or antiInfLoop >= 100
	local hasExit = false
	for i = 0, DoorSlot.NUM_DOOR_SLOTS - 1 do
		if EdithRestored.Room():GetDoor(i) then
			if pathFinderNPC.Pathfinder:HasPathToPos(EdithRestored.Room():GetDoor(i).Position) then
				hasExit = true
				break
			end
		end
	end
	while not hasExit do
		pathFinderNPC.Position = EdithRestored.Room():GetRandomPosition(20)
		hasExit = pathFinderNPC.Pathfinder:HasPathToPos(GetRandomDoorPosition(rng), false)
	end
	local finalPos = pathFinderNPC.Position
	pathFinderNPC:Remove()
	return finalPos
end

---@param player EntityPlayer
---@param statue EntityEffect
---@return Vector?
local function GetPosition(player, statue)
	local data = EdithRestored:GetData(player)
	local statueData = EdithRestored:GetData(statue)

	local enemies = Helpers.GetEnemies()
	local rng = player:GetCardRNG(EdithRestored.Enums.Pickups.Cards.CARD_SOUL_EDITH)
	local finalPos = data.StartPosition

	local grids = {}
	for i = 0, EdithRestored.Room():GetGridSize() - 1 do
		local grid = EdithRestored.Room():GetGridEntity(i)
		if grid then
			table.insert(grids, grid)
		end
	end
	local skullRocks = Helpers.Filter(grids, function(index, rock)
		return rock.State ~= 2 and rock:GetType() == GridEntityType.GRID_ROCK_ALT2
	end)
	local doors = Helpers.Filter(grids, function(index, door)
		---@cast door GridEntity
		return door:GetType() == GridEntityType.GRID_DOOR and door:ToDoor():CanBlowOpen() and door:ToDoor():IsLocked()
	end)
	local ssRocks = Helpers.Filter(grids, function(index, rock)
		return rock.State ~= 2 and rock:GetType() == GridEntityType.GRID_ROCK_SS
	end)
	local tintedRocks = Helpers.Filter(grids, function(index, rock)
		return rock.State ~= 2 and rock:GetType() == GridEntityType.GRID_ROCKT
	end)
	local statues = Helpers.Filter(grids, function(index, statue)
		return statue:GetType() == GridEntityType.GRID_STATUE and statue.State ~= 2
	end)
	local rocks = Helpers.Filter(grids, function(index, rock)
		return rock.State ~= 2
			and (
				rock:GetType() == GridEntityType.GRID_ROCK
				or rock:GetType() == GridEntityType.GRID_ROCK_SPIKED
				or rock:GetType() == GridEntityType.GRID_ROCK_ALT
				or rock:GetType() == GridEntityType.GRID_ROCK_BOMB
				or rock:GetType() == GridEntityType.GRID_ROCK_GOLD
			)
	end)
	local fires = Helpers.Filter(Isaac.FindByType(EntityType.ENTITY_FIREPLACE), function(index, fire)
		return fire.Variant ~= 4 and fire:ToNPC().State ~= NpcState.STATE_IDLE
	end)
	local poops = Helpers.Filter(grids, function(index, poop)
		return poop:GetType() == GridEntityType.GRID_POOP and poop.State < 1000
	end)
	local shopKeepers = Isaac.FindByType(EntityType.ENTITY_SHOPKEEPER)
	local destrGrids =
		Helpers.MergeTables(skullRocks, doors, ssRocks, tintedRocks, statues, rocks, fires, poops, shopKeepers)

	local antiInfLoop = 0
	local chosen = false
	repeat
		if #enemies > 0 then
			finalPos = enemies[rng:RandomInt(1, #enemies)].Position
			chosen = true
		end
		antiInfLoop = antiInfLoop + 1
	until antiInfLoop >= 100
		or player.CanFly
		or EdithRestored.Room():GetGridCollisionAtPos(finalPos) ~= GridCollisionClass.COLLISION_PIT and chosen
	if antiInfLoop >= 100 then
		antiInfLoop = 0
		while
			antiInfLoop < 100
			and not player.CanFly
			and EdithRestored.Room():GetGridCollisionAtPos(finalPos) ~= GridCollisionClass.COLLISION_PIT
		do
			if #destrGrids > 0 then
				finalPos = destrGrids[rng:RandomInt(1, #destrGrids)].Position
			else
				finalPos = EdithRestored.Room():GetRandomPosition(20)
			end
			antiInfLoop = antiInfLoop + 1
		end
	end

	if data.StoneJumps == 1 then
		finalPos = GetAntiSoftLockPosition(
			{ { Position = finalPos }, { Position = data.StartPosition } },
			data.StartPosition,
			rng,
			player.CanFly
		)
	end
	while
		EdithRestored.Room():GetGridCollisionAtPos(finalPos) == GridCollisionClass.COLLISION_PIT
		and not player.CanFly
	do
		finalPos = EdithRestored.Room():GetRandomPosition(20)
	end
	data.StartPosition = nil
	return finalPos
end

local function RemoveJumps(player)
	local data = EdithRestored:GetData(player)
	data.Statue = nil
	data.StartPosition = nil
end

---@param player EntityPlayer
---@param statue EntityEffect
local function JumpInit(player, statue)
	local data = EdithRestored:GetData(player)
	local statueData = EdithRestored:GetData(statue)
	data.StartPosition = data.StartPosition or player.Position
	if statueData.StoneJumps <= 0 then
		RemoveJumps(player)
		statueData.StoneJumps = nil
		statue:Remove()
		return
	end
	statue:GetSprite():Play(statueData.StoneJumps <= 1 and "BigJump" or "EdithJump", true)
end

---@param soe Card
---@param player EntityPlayer
---@param useflags integer | UseFlag
function SoulOfEdith:UseSoulEdith(soe, player, useflags)
	local data = EdithRestored:GetData(player)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL then
		player:SwapForgottenForm(true, false)
	end
	Helpers.RemoveEdithTarget(player)
	if useflags & UseFlag.USE_NOANIM == 0 then
		player:AnimateCard(-1, "HideItem")
	end
	if JumpLib:GetData(player).Jumping then
		JumpLib:QuitJump(player)
	end
	if not data.Statue then
		data.Statue = Isaac.Spawn(
			EntityType.ENTITY_EFFECT,
			EdithRestored.Enums.Entities.SALT_STATUE.Variant,
			0,
			player.Position,
			Vector.Zero,
			player
		):ToEffect()
		data.Statue:FollowParent(player)
	end
	local statueData = EdithRestored:GetData(data.Statue)
	if useflags & UseFlag.USE_CARBATTERY > 0 then
		statueData.StoneJumps = (statueData.StoneJumps or 0) + 1
	else
		Helpers.PlaySND(EdithRestored.Enums.SFX.Cards.CARD_SOUL_EDITH)
		sfx:Play(SoundEffect.SOUND_STONE_IMPACT)
		statueData.StoneJumps = 4
		JumpInit(player, data.Statue)
		player:AddCacheFlags(CacheFlag.CACHE_COLOR, true)
	end
	data.EdithTargetMovementPosition = nil
end
EdithRestored:AddCallback(
	ModCallbacks.MC_USE_CARD,
	SoulOfEdith.UseSoulEdith,
	EdithRestored.Enums.Pickups.Cards.CARD_SOUL_EDITH
)

---@param collectible CollectibleType
---@param rng RNG
---@param player EntityPlayer
---@param useflags integer | UseFlag
---@param slot ActiveSlot
---@param vardata integer
---@return boolean | table?
function SoulOfEdith:UseSoulEdithWithClearRune(collectible, rng, player, useflags, slot, vardata)
	if player:GetCard(0) == EdithRestored.Enums.Pickups.Cards.CARD_SOUL_EDITH then
		player:UseCard(EdithRestored.Enums.Pickups.Cards.CARD_SOUL_EDITH, useflags | UseFlag.USE_NOANIM)
		return true
	end
end
EdithRestored:AddPriorityCallback(
	ModCallbacks.MC_PRE_USE_ITEM,
	CallbackPriority.IMPORTANT,
	SoulOfEdith.UseSoulEdithWithClearRune,
	CollectibleType.COLLECTIBLE_CLEAR_RUNE
)

function SoulOfEdith:NoStatueDamage(entity, damage, flags, source, cd)
	if entity:ToPlayer() then
		local player = entity:ToPlayer()
		---@cast player EntityPlayer
		local data = EdithRestored:GetData(player)
		if data.Statue then
			return false
		end
	end
end
EdithRestored:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, SoulOfEdith.NoStatueDamage, EntityType.ENTITY_PLAYER)

---@param player EntityPlayer
function SoulOfEdith:Landing(player, jumpData, inPit)
	if not inPit then
		local data = EdithRestored:GetData(player)
		local statueData = EdithRestored:GetData(data.Statue)
		if statueData.StoneJumps then
			statueData.StoneJumps = math.max(statueData.StoneJumps - 1, 0)
			Helpers.Stomp(player, 1, statueData.StoneJumps == 0, nil, nil, { Tooth = true })
			if statueData.StoneJumps == 0 then
				sfx:Play(SoundEffect.SOUND_STONE_IMPACT)
				player:AddCollectibleEffect(CollectibleType.COLLECTIBLE_BOOK_OF_SHADOWS, false, 45, true)
			end
			for _, pickup in ipairs(Isaac.FindInRadius(player.Position, 30, EntityPartition.PICKUP)) do
				pickup.Velocity = Vector.Zero
			end
			player.Velocity = Vector.Zero
			if data.EdithJumpTarget then
				data.EdithJumpTarget:Remove()
				data.EdithJumpTarget = nil
			end

			data.TargetJumpPos = nil

			for _, v in pairs(Isaac.FindInRadius(player.Position, 55, EntityPartition.BULLET)) do
				local projectile = v:ToProjectile() ---@cast projectile EntityProjectile
				local angle = ((player.Position - projectile.Position) * -1):GetAngleDegrees()
				projectile.Velocity = Vector.FromAngle(angle):Resized(10)
				projectile:AddProjectileFlags(ProjectileFlags.CANT_HIT_PLAYER)
				projectile:AddProjectileFlags(ProjectileFlags.HIT_ENEMIES)
			end
		end
	end
end
EdithRestored:AddCallback(
	JumpLib.Callbacks.ENTITY_LAND,
	SoulOfEdith.Landing,
	{ tag = "SoulEdithJump", type = EntityType.ENTITY_PLAYER }
)

function SoulOfEdith:NewRoom()
	for _, player in ipairs(PlayerManager.GetPlayers()) do
		RemoveJumps(player)
		player:AddCacheFlags(CacheFlag.CACHE_COLOR, true)
	end
end
EdithRestored:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, SoulOfEdith.NewRoom)

function SoulOfEdith:ReturnColors(effect)
	if
		effect.Type == EntityType.ENTITY_EFFECT
		and effect.Variant == EdithRestored.Enums.Entities.SALT_STATUE.Variant
		and effect.SpawnerEntity
		and effect.SpawnerEntity:ToPlayer()
	then
		effect.SpawnerEntity:ToPlayer():AddCacheFlags(CacheFlag.CACHE_COLOR, true)
	end
end
EdithRestored:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, SoulOfEdith.ReturnColors)

---@param statue EntityEffect
function SoulOfEdith:StatueJumping(statue)
	local data = EdithRestored:GetData(statue)
	local player = statue.SpawnerEntity
	if not player or not player:ToPlayer() then
		statue:Remove()
		return
	end
	player = player:ToPlayer()
	---@cast player EntityPlayer
	local playerData = EdithRestored:GetData(player)
	if data.StoneJumps then
		local sprite = statue:GetSprite()
		if JumpLib:CanJump(player) and (sprite:IsFinished("EdithJump") or sprite:IsFinished("BigJump")) then
			JumpInit(player, statue)
		end
		if sprite:GetAnimation() == "EdithJump" and sprite:GetFrame() < 17 then
			if sprite:GetFrame() == 5 then
				JumpLib:Jump(player, {
					Height = Helpers.GetJumpHeight(),
					Speed = Helpers.GetJumpGravity(),
					Flags = JumpLib.Flags.NO_PITFALL
						| JumpLib.Flags.FAMILIAR_FOLLOW_ORBITALS
						| JumpLib.Flags.FAMILIAR_FOLLOW_TEARCOPYING
						| JumpLib.Flags.DISABLE_COOL_BOMBS
						| JumpLib.Flags.KNIFE_DISABLE_ENTCOLL,
					Tags = { "SoulEdithJump" },
				})
			end
			if sprite:GetFrame() > 5 and sprite:GetFrame() < 10 then
				playerData.TargetJumpPos = playerData.TargetJumpPos or GetPosition(player, statue)
				player.Velocity = (playerData.TargetJumpPos - player.Position):Normalized()
					* (playerData.TargetJumpPos - player.Position):Length()
					/ 7
			end
		end
		if sprite:GetAnimation() == "BigJump" and sprite:GetFrame() < 20 then
			if sprite:GetFrame() == 10 then
				JumpLib:Jump(player, {
					Height = 25,
					Speed = 3,
					Flags = JumpLib.Flags.NO_PITFALL
						| JumpLib.Flags.FAMILIAR_FOLLOW_ORBITALS
						| JumpLib.Flags.FAMILIAR_FOLLOW_TEARCOPYING
						| JumpLib.Flags.DISABLE_COOL_BOMBS
						| JumpLib.Flags.KNIFE_DISABLE_ENTCOLL,
					Tags = { "SoulEdithJump" },
				})
			end
			if sprite:GetFrame() > 15 then
				playerData.TargetJumpPos = playerData.TargetJumpPos or GetPosition(player, statue)
				player.Velocity = (playerData.TargetJumpPos - player.Position):Normalized()
					* (playerData.TargetJumpPos - player.Position):Length()
					/ 3
			end
		end
	else
		playerData.Statue = nil
		statue:Remove()
	end
end
EdithRestored:AddCallback(
	ModCallbacks.MC_POST_EFFECT_UPDATE,
	SoulOfEdith.StatueJumping,
	EdithRestored.Enums.Entities.SALT_STATUE.Variant
)

---@param player EntityPlayer
function SoulOfEdith:PlayerVisible(player, cacheFlags)
	local data = EdithRestored:GetData(player)
	if data.Statue then
		data.PrevColor = player.Color
		player.Color = Color(1, 1, 1, 0)
	elseif data.PrevColor then
		player.Color = data.PrevColor
		data.PrevColor = nil
	end
end
EdithRestored:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, SoulOfEdith.PlayerVisible, CacheFlag.CACHE_COLOR)

function SoulOfEdith:StatueCollisionWithPickups(player, collider)
	if EdithRestored:GetData(player).Statue and collider and (collider:ToPickup() or collider:ToNPC()) then
		return true
	end
end
EdithRestored:AddCallback(ModCallbacks.MC_PRE_PLAYER_COLLISION, SoulOfEdith.StatueCollisionWithPickups)

function SoulOfEdith:PickupsCollisionWithStatue(pickup, collider)
	if collider and collider:ToPlayer() and EdithRestored:GetData(collider).Statue then
		return true
	end
end
EdithRestored:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, SoulOfEdith.PickupsCollisionWithStatue)

function SoulOfEdith:NoStatueInput(entity, hook, button)
	if entity and entity:ToPlayer() then
		local player = entity:ToPlayer()
		local data = EdithRestored:GetData(player)
		if data.Statue then
			if hook == InputHook.GET_ACTION_VALUE then
				return 0
			else
				return false
			end
		end
	end
end
EdithRestored:AddCallback(ModCallbacks.MC_INPUT_ACTION, SoulOfEdith.NoStatueInput)

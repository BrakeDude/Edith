local SaltRock = {}
local SaltCreepVar = EdithRestored.Enums.Entities.SALT_CREEP.Variant
local SaltCreepSubtype = EdithRestored.Enums.Entities.SALT_CREEP.SubType
local SaltQuantity = 4
local spawnDegree = 360 / SaltQuantity
local Helpers = EdithRestored.Helpers

local function ChangeToEdithTear(tear)
	tear:ChangeVariant(TearVariant.ROCK)
	tear.Color = Color(
		tear.Color.R + 0.8,
		tear.Color.G + 1,
		tear.Color.B + 1,
		tear.Color.A,
		tear.Color.RO,
		tear.Color.GO,
		tear.Color.BO
	)
end

---@param grid GridEntity
local function IsGridSaltRock(grid)
	return grid:GetVariant() == EdithRestored.Enums.RockVariant.ROCK_SALT
end

---@param grid GridEntity
local function NotGridSaltRock(grid)
	return grid:GetVariant() ~= EdithRestored.Enums.RockVariant.ROCK_SALT
end

---@param grid GridEntity
local function UpdateRock(grid)
	local color = grid:GetSprite().Color
	color:SetColorize(4, 4, 4, 1)
	grid:GetSprite().Color = color
	if grid.State ~= 2  then
		local rng = RNG()
		local desc = grid:GetSaveState()
		local seed = desc and desc.SpawnSeed or room:GetDecorationSeed()

		rng:SetSeed(seed, 35)
	
		local salt = Isaac.Spawn(EntityType.ENTITY_EFFECT, SaltCreepVar, SaltCreepSubtype, grid.Position, Vector.Zero, nil):ToEffect()
	--	if not salt then return end

		salt:SetTimeout(-1)
		salt.Scale = (salt.Scale * 2.5)
		EdithRestored:GetData(salt).GridParent = grid
	end
end

---@param grid GridEntity
function SaltRock:Spawn(grid)
	local room = EdithRestored.Room()
	if NotGridSaltRock(grid) then
		if not (PlayerManager.AnyoneHasTrinket(EdithRestored.Enums.TrinketType.TRINKET_SALT_ROCK) and room:IsFirstVisit()) then return end
		local rockLimit = PlayerManager.GetTotalTrinketMultiplier(EdithRestored.Enums.TrinketType.TRINKET_SALT_ROCK)
		local rocks = 0
		for i = 0, room:GetGridSize() - 1 do
			if room:GetGridEntity(i) and room:GetGridEntity(i):ToRock()
			and IsGridSaltRock(room:GetGridEntity(i)) then
				rocks = rocks + 1
			end
		end
		if rocks > rockLimit then
			return
		end
		local rng = RNG()
		local desc = grid:GetSaveState()
		local seed = desc and desc.SpawnSeed or room:GetDecorationSeed()

		rng:SetSeed(seed, 35)

		if rng:RandomFloat() < 0.85 then return end
		grid:SetVariant(EdithRestored.Enums.RockVariant.ROCK_SALT)
		for _ = 1, rng:RandomInt(2, 5) do
			Isaac.Spawn(1000, EffectVariant.TOOTH_PARTICLE, 0, grid.Position, RandomVector() * rng:RandomFloat() * rng:RandomInt(6), nil):ToEffect()
		end
	end
end
EdithRestored:AddCallback(ModCallbacks.MC_POST_GRID_ENTITY_SPAWN, SaltRock.Spawn, GridEntityType.GRID_ROCK)

---@param grid GridEntity
function SaltRock:UpdateRockSprite(grid)
	if IsGridSaltRock(grid) then
		if EdithRestored.Room():GetFrameCount() < 1 then
			UpdateRock(grid)
		end
		if grid.State ~= 2 then
			for _, ent in ipairs(Helpers.GetEnemiesInRadius(grid.Position, 20, false, false, true, true)) do
				ent:TakeDamage(20, DamageFlag.DAMAGE_SPIKES | DamageFlag.DAMAGE_COUNTDOWN, EntityRef(nil), 5)
				ent:AddKnockback(EntityRef(nil), (ent.Position - grid.Position):Resized(5), 5, false)
			end
		end
	end
end
EdithRestored:AddCallback(ModCallbacks.MC_POST_GRID_ENTITY_ROCK_UPDATE, SaltRock.UpdateRockSprite, GridEntityType.GRID_ROCK)

---@param grid GridEntity
function SaltRock:OnKillSaltRock(grid)
	if NotGridSaltRock(grid) then return end
	local room = EdithRestored.Room()

	local rng = RNG()
	local desc = grid:GetSaveState()
	local seed = desc and desc.SpawnSeed or room:GetDecorationSeed()
	rng:SetSeed(seed, 35)

	for _ = 1, rng:RandomInt(5, 8) do
		local tear = Isaac.Spawn(EntityType.ENTITY_TEAR, 0, 0, grid.Position, RandomVector():Resized(15), nil):ToTear()
		tear:AddTearFlags(TearFlags.TEAR_SPECTRAL)
        ChangeToEdithTear(tear)
		tear.CollisionDamage = 4 + EdithRestored.Level:GetAbsoluteStage()
    end

	EdithRestored.SFX:Play(SoundEffect.SOUND_MAGGOT_ENTER_GROUND)
end
EdithRestored:AddCallback(ModCallbacks.MC_POST_GRID_ROCK_DESTROY, SaltRock.OnKillSaltRock, GridEntityType.GRID_ROCK)

---@param salt EntityEffect
function SaltRock:SaltTimeout(salt)
    if salt.SubType ~= SaltCreepSubtype then return end
	local data = EdithRestored:GetData(salt)
    if data.GridParent and data.GridParent:ToRock() then		
		if data.GridParent.State == 2 then
			data.GridParent = nil
			salt:SetTimeout(60)
		end
	end
end
EdithRestored:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, SaltRock.SaltTimeout, SaltCreepVar)
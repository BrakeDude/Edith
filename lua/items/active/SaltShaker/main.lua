local SaltShakerLocal = {}
local Helpers = EdithRestored.Helpers

local SaltCreepVar = EdithRestored.Enums.Entities.SALT_CREEP.Variant
local SaltCreepSubtype = EdithRestored.Enums.Entities.SALT_CREEP.SubType

local SaltQuantity = 16
local spawnDegree = 360 / SaltQuantity

local sfx = EdithRestored.SFX

---@param collectible CollectibleType | integer
---@param rng RNG
---@param player EntityPlayer
---@param flags UseFlag | integer
---@param slot ActiveSlot | integer
---@param customVarData integer
---@return table | boolean?
function SaltShakerLocal:UseShaker(collectible, rng, player, flags, slot, customVarData)
    local CarBatteryUse = (flags == flags | UseFlag.USE_CARBATTERY)
    if CarBatteryUse then return end

    local SaltTimeOut = player:HasCollectible(CollectibleType.COLLECTIBLE_CAR_BATTERY) and 480 or 240
    local ExistintSalt = Isaac.FindByType(EntityType.ENTITY_EFFECT, SaltCreepVar, SaltCreepSubtype)

    for _, ExistSalt in ipairs(ExistintSalt) do
        if ExistSalt.SpawnerEntity and GetPtrHash(ExistSalt.SpawnerEntity) == GetPtrHash(player) then
            ExistSalt:ToEffect():SetTimeout(1)
        end
    end

    for i = 1, SaltQuantity do
        local salt = Isaac.Spawn(EntityType.ENTITY_EFFECT, SaltCreepVar, SaltCreepSubtype, player.Position + Vector.FromAngle(spawnDegree * i) * 60, Vector.Zero, player):ToEffect()
        if not salt then return end

        for _ = 1, rng:RandomInt(2, 5) do
            Isaac.Spawn(1000, EffectVariant.TOOTH_PARTICLE, 0, salt.Position, RandomVector() * rng:RandomFloat() * rng:RandomInt(6), player):ToEffect()
        end

        salt:SetTimeout(SaltTimeOut)
    end

    local SoundPitch = rng:RandomInt(900, 1100) / 1000
    sfx:Play(EdithRestored.Enums.SFX.SaltShaker.SHAKE, 1, 0, false, SoundPitch)

    return {Discharge = true, Remove = false, ShowAnim = true}
end
EdithRestored:AddCallback(ModCallbacks.MC_USE_ITEM, SaltShakerLocal.UseShaker, EdithRestored.Enums.CollectibleType.COLLECTIBLE_SALT_SHAKER)

---@param creep EntityEffect
function SaltShakerLocal:SaltInit(creep)
    local sprite = creep:GetSprite()
    local rng = RNG(creep.InitSeed)
    local randomNum = tostring(rng:RandomInt(1, 6))
    sprite:Play("SmallBlood0" .. randomNum, true)
end
EdithRestored:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, SaltShakerLocal.SaltInit, SaltCreepVar)

---@param creep EntityEffect
function SaltShakerLocal:CreepUpdate(creep)
    if creep.SubType ~= SaltCreepSubtype then return end
    local enemies = Helpers.GetEnemiesInRadius(creep.Position, 20 * creep.Scale)

    for _, enemy in ipairs(enemies) do
        
        if (not enemy:HasEntityFlags(EntityFlag.FLAG_FEAR)) then
            enemy:AddFear(EntityRef(creep), 30)
        end           
    end
end
EdithRestored:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, SaltShakerLocal.CreepUpdate, SaltCreepVar)
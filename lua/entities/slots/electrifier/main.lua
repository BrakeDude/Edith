local Electrifier = {}
local Helpers = EdithRestored.Helpers
local game = EdithRestored.Game
local itemPool = game:GetItemPool()
local itemConfig = Isaac.GetItemConfig()

local trinketList = {
    TrinketType.TRINKET_AAA_BATTERY,
    TrinketType.TRINKET_CHARGED_PENNY,
    TrinketType.TRINKET_DIM_BULB,
    TrinketType.TRINKET_VIBRANT_BULB,
    TrinketType.TRINKET_WATCH_BATTERY
}

local function GetCharges()
    return EdithRestored:GetDefaultFileSave("ElectrifierCharges")
end

local function SetCharges(num)
    EdithRestored:AddDefaultFileSave("ElectrifierCharges", num)
end

local function AddCharges(num)
    SetCharges(GetCharges() + num)
end

local function GetNotSpawnedTrinkets()
    local list = {}
    for _,trinket in pairs(trinketList) do
        if itemPool:HasTrinket(trinket) then
            table.insert(list, trinket)
        end
    end
    return list
end

---@param slot EntitySlot
---@param collider Entity
---@param low boolean
---@return boolean? | nil?
function Electrifier:onCollision(slot, collider, low)
    if collider and collider:ToPlayer() then
        local player = collider:ToPlayer()
        ---@cast player EntityPlayer
        if slot:GetState() == 1 then
            for i = 0,2 do
                local item = player:GetActiveItem(i)
                local conf = itemConfig:GetCollectible(item)
                if conf and conf.ChargeType == ItemConfig.CHARGE_NORMAL then
                    local charge = Helpers.GetCharge(player, i)
                    if charge >= 1 then
                        player:AddActiveCharge(-1, i, true, false, true)
                        slot:SetTimeout(30)
                        slot:SetState(2)
                        local BatteryEffect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HEART, 3, player.Position, Vector.Zero, nil):ToEffect()
                        BatteryEffect.SpriteOffset = Vector(0,-15)
                        BatteryEffect.DepthOffset = 15
                        SFXManager():Play(SoundEffect.SOUND_BEEP, 1, 0)
                        SFXManager():Play(SoundEffect.SOUND_BATTERYDISCHARGE, 1, 2, false, 1, 0)
                        game:GetHUD():FlashChargeBar(player, i)
                        return
                    end
                end
            end
        end
    end
end
EdithRestored:AddCallback(ModCallbacks.MC_PRE_SLOT_COLLISION, Electrifier.onCollision, EdithRestored.Enums.Slots.ELECTRIFIER.Variant)

---@param slot EntitySlot
function Electrifier:onInit(slot)
    slot:SetState(1)
end
EdithRestored:AddCallback(ModCallbacks.MC_POST_SLOT_INIT, Electrifier.onInit, EdithRestored.Enums.Slots.ELECTRIFIER.Variant)

local function ChangeAltarSprite(pickup)
    if pickup.SpawnerType == EdithRestored.Enums.Slots.ELECTRIFIER.Type and pickup.SpawnerVariant == EdithRestored.Enums.Slots.ELECTRIFIER.Variant and pickup.Variant == PickupVariant.PICKUP_COLLECTIBLE and not pickup:IsShopItem() then
        local sprite = pickup:GetSprite()
        pickup:SetAlternatePedestal(PedestalType.FORTUNE_TELLING_MACHINE)
        sprite:ReplaceSpritesheet(5, "gfx/items/Electrifier_altar.png")
        sprite:LoadGraphics()
    end
end

function Electrifier:onItemAlatarRenderRoomEnter()
    for _,pickup in ipairs(Isaac.FindByType(5,100)) do
        pickup = pickup:ToPickup()
        ChangeAltarSprite(pickup)
    end
end
EdithRestored:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, Electrifier.onItemAlatarRenderRoomEnter)

---@param slot EntitySlot
function Electrifier:onDeath(slot)
    local rng = slot:GetDropRNG()
    if slot:GetPrizeType() == 2 then
        slot.Velocity = Vector.Zero
        slot.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
        slot.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
        local item = itemPool:GetCollectible(ItemPoolType.POOL_BATTERY_BUM, true, math.max(1,Random()), CollectibleType.COLLECTIBLE_BATTERY)
        local pickup = Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, item, slot.Position, Vector.Zero, nil):ToPickup()
        pickup:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
        pickup.SpawnerType = EdithRestored.Enums.Slots.ELECTRIFIER.Type
        pickup.SpawnerVariant = EdithRestored.Enums.Slots.ELECTRIFIER.Variant
        slot.Position = pickup.Position
        ChangeAltarSprite(pickup)
        slot:GetData().RemoveTimer = 5
        SetCharges(0)
    else
        local gotTrinket = false
        local items = math.ceil(GetCharges() / 3 * 2)
        AddCharges(-items)
        while items > 0 do
            local velocity = EntityPickup.GetRandomPickupVelocity(slot.Position, rng, 1)
            ---@cast velocity Vector
            local list = GetNotSpawnedTrinkets()
            if rng:RandomFloat() >= 0.7 and #list > 0 and not gotTrinket and items >= 5 then
                local trinket = list[rng:RandomInt(1, #list)]
                itemPool:RemoveTrinket(trinket)
                Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TRINKET, trinket, slot.Position, velocity, nil)
                gotTrinket = true
                items = items - 5
            else
                if rng:RandomFloat() >= 0.8 and items >= 3 then
                    items = items - 3
                else
                    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_LIL_BATTERY, BatterySubType.BATTERY_MICRO, slot.Position, velocity, nil)
                    items = items - 1
                end
            end
        end
    end
    return false
end
EdithRestored:AddCallback(ModCallbacks.MC_PRE_SLOT_CREATE_EXPLOSION_DROPS, Electrifier.onDeath, EdithRestored.Enums.Slots.ELECTRIFIER.Variant)

---@param slot EntitySlot
function Electrifier:onUpdate(slot)
    local s = slot:GetSprite()
    local rng = slot:GetDropRNG()
    if s:IsFinished("Appear") or slot:GetState() == 1 and not s:IsPlaying("Idle") and not s:IsPlaying("Appear") then
        s:Play("Idle", true)
        slot:SetState(1)
    end
    if slot:GetState() == 3 and not (s:GetAnimation() == "Broken" or s:GetAnimation() == "Death") then
        s:Play("Death", true)
    end
    if s:IsFinished("Death") then
        s:Play("Broken", true)
    end
    if slot:GetState() == 2 and s:IsPlaying("Idle") then
        s:Play("Initiate", true)
    end
    if s:IsFinished("Initiate") then
        if rng:RandomFloat() >= (0.95 - slot:GetDonationValue() * 0.015 - GetCharges() * 0.005) then
            local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BOMB_EXPLOSION, 0, slot.Position, Vector.Zero, nil):ToEffect()
            slot:SetPrizeType(rng:RandomFloat() >= math.max(0.5, 0.9 + GetCharges() * 0.015) and 2 or 1)
            slot:TakeDamage(2, DamageFlag.DAMAGE_EXPLOSION, EntityRef(effect), 0)
            s:Play("Death", true)
            slot:SetState(3)
        else
            s:Play("Prize", true)
        end
    end
    if s:IsEventTriggered("Prize") then
        AddCharges(1)
        slot:SetDonationValue(slot:GetDonationValue() + 1)
        local BatteryEffect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BATTERY, 0, slot.Position, Vector.Zero, nil):ToEffect()
        BatteryEffect.SpriteOffset = Vector(0,-15)
        BatteryEffect.DepthOffset = 15
        SFXManager():Play(SoundEffect.SOUND_BEEP, 1, 0)
        SFXManager():Play(SoundEffect.SOUND_SLOTSPAWN, 1, 0, false)
        for _ = 1, rng:RandomInt(2,4) do
            Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, CoinSubType.COIN_PENNY, slot.Position, EntityPickup.GetRandomPickupVelocity(slot.Position, rng, 1), nil)
        end
    end
    if slot:GetData().RemoveTimer then
        local data = slot:GetData()
        data.RemoveTimer = data.RemoveTimer - 1
        if data.RemoveTimer <= 0 then
            slot:Remove()
        end
    end
end
EdithRestored:AddCallback(ModCallbacks.MC_POST_SLOT_UPDATE, Electrifier.onUpdate, EdithRestored.Enums.Slots.ELECTRIFIER.Variant)

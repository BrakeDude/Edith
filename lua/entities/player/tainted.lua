---@diagnostic disable: need-check-nil
local Helpers = EdithRestored.Helpers
local game = Game()
local Tainted = {}
local sfx = SFXManager()

---@param player EntityPlayer
---@return boolean
local function IsTaintedEdith(player)
    return Helpers.IsTaintedEdith(player)
end

---@param player EntityPlayer
local function PlayerCanUseBombs(player)
    return player:GetNumBombs() > 0 or player:HasGoldenBomb()
end

local function IsBombDash(player, data)
    return data.ShouldConsumeBomb and PlayerCanUseBombs(player)
end

local function IsDashing(data)
    return EdithRestored:IsEdithSliding(data) and data.RamState
end 

---@param player EntityPlayer
---@param data table
local function GetRemainingGrids(player, data)
    if not EdithRestored:IsEdithSliding(data) then return 0 end

    return math.ceil(player.Position:Distance(data.EdithTargetMovementPosition) / 40)
end

local OppositeDirectionActions = {
    [Direction.UP] = ButtonAction.ACTION_DOWN,
    [Direction.DOWN] = ButtonAction.ACTION_UP,
    [Direction.LEFT] = ButtonAction.ACTION_RIGHT,
    [Direction.RIGHT] = ButtonAction.ACTION_LEFT,
}

---@param entity Entity
---@param duration integer
---@param pos? Vector
local function SpawnPepperCreep(entity, duration, pos)
    local pepperCreep = Isaac.Spawn(EntityType.ENTITY_EFFECT, EdithRestored.Enums.Entities.PEPPER_CREEP.Variant, EdithRestored.Enums.Entities.PEPPER_CREEP.SubType, pos or entity.Position, Vector.Zero, entity):ToEffect() ---@cast pepperCreep EntityEffect

    pepperCreep.Color = Color(0, 0, 0)
    pepperCreep:SetTimeout(duration)
end

local function SetDashColor(player, data)
    local red = data.ShouldConsumeBomb and 0.3 or 0
    sfx:Play(SoundEffect.SOUND_STONE_IMPACT, 0.25, 0, false, 2)
    player:SetColor(Color(2, 2, 2, 1, red), 5, 100, true, false)
    data.RamGlowCounter = 0
end 

---@param entity Entity
---@param radius number 
local function SpawnPepperOnGridInRadius(entity, radius)
    local room = game:GetRoom()
    radius = radius or 10
    for i = 0, (room:GetGridSize()) do
		local gridPos = room:GetGridPosition(i)
        if entity.Position:Distance(gridPos) > radius then goto continue end        
        SpawnPepperCreep(entity, 150, gridPos)
		::continue::
    end
end

---@param data table
---@param slides number
function EdithRestored:AddExtraTilesToSlide(data, slides)
    local moveDir = TSIL.Vector.VectorToDirection(data.EdithTargetMovementDirection) --[[@as Direction]]
	local mirrorWorldReverser = Helpers.InMirrorWorld() and -1 or 1
	local gridMove = 40 * Helpers.Round(slides, 0)
	local params = {
		[Direction.LEFT] = Vector(-gridMove, 0) * mirrorWorldReverser,
		[Direction.RIGHT] = Vector(gridMove, 0) * mirrorWorldReverser,
		[Direction.UP] = Vector(0, -gridMove),
		[Direction.DOWN] = Vector(0, gridMove),
	}

	local ButtomParams = params[moveDir]

    data.EdithTargetMovementPosition = data.EdithTargetMovementPosition + ButtomParams
end

---@param ent Entity
local function IsEnemy(ent)
    return ent:IsActiveEnemy() and ent:IsVulnerableEnemy()
end

---@param player EntityPlayer
---@param collider? Entity
local function TriggerDashCollision(player, collider)
    local data = EdithRestored:GetData(player)
    local isDashing = IsDashing(data)

    if not isDashing then return end

    local StompDamageMult = data.IsInPepper and 1.5 or 1

    sfx:Play(SoundEffect.SOUND_MEATY_DEATHS)

    if data.ShouldConsumeBomb and not player:HasGoldenBomb() then        
        player:AddBombs(-1)
    end

    player:SetMinDamageCooldown(30)

    if not collider then return end 

    local ptrHash = GetPtrHash(collider)

    if data.SlideHitBlacklist[ptrHash] == true then return end
    if collider.Type == EntityType.ENTITY_STONEY then return end
    if not IsEnemy(collider) then return end

    Helpers.Stomp(player, StompDamageMult, true, IsBombDash(player, data), true)

    data.SlideHitBlacklist[ptrHash] = true

    if collider.HitPoints <= data.StompDamage then 
        -- SpawnPepperOnGridInRadius(collider, (collider.Size + 30) * 1.5)
    else
        data.ExtraIFrames = data.ExtraIFrames or 0
        data.ExtraIFrames = data.ExtraIFrames + 5

        if GetRemainingGrids(player, data) <= 2 then
            EdithRestored:AddExtraTilesToSlide(data, 1)
        else
            data.RamState = false
            EdithRestored:StopSlide(data)
        end
    end
end

local function isPressingOppositeDashDirectionKey(player, data)
    if not data.EdithTargetMovementDirection then return end

    local moveDir = TSIL.Vector.VectorToDirection(data.EdithTargetMovementDirection)

    for dir, key in pairs(OppositeDirectionActions) do
        if moveDir ~= dir then goto continue end
        if not Input.IsActionTriggered(key, player.ControllerIndex) then goto continue end

        EdithRestored:StopSlide(data)
        data.RamState = false
        data.StoppedDash = true

        ::continue::
    end
end 

---@param player EntityPlayer
---@param data table
local function IsSlideFinished(player, data)
    if not data.EdithTargetMovementPosition then return false end

    return data.SlideCounter ~= 0 and TSIL.Vector.VectorFuzzyEquals(player.Position, data.SlideTarget, 2.1)
end

---@param player EntityPlayer
function Tainted:OnTaintedInit(player)
    if not IsTaintedEdith(player) then return end

    local mySprite = player:GetSprite()
	mySprite:Load(EdithRestored.Enums.PlayerSprites.EDITH_B, true)
	mySprite:Update()

    player:AddSoulHearts(-6)
    player:AddBlackHearts(4)
    player:AddSoulHearts(2)
end
EdithRestored:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, Tainted.OnTaintedInit)

---@param player EntityPlayer
function Tainted:OnTaintedUpdate(player)
    if not IsTaintedEdith(player) then return end
    local data = EdithRestored:GetData(player)
    local ctrlIdx = player.ControllerIndex 

    data.TriggerMove = data.TriggerMove or false
    data.SlideCharge = data.SlideCharge or 0
    data.Slidespeed = data.Slidespeed or 0
    data.StaticSlideCharge = data.StaticSlideCharge or 0
    data.MoveGrids = data.MoveGrids or 0
    data.ShouldConsumeBomb = data.ShouldConsumeBomb or false
    data.ExtraIFrames = data.ExtraIFrames or 0
    data.SlideHitBlacklist = data.SlideHitBlacklist or {} 
    data.SlideTarget = data.SlideTarget or data.EdithTargetMovementPosition

    if Input.IsActionTriggered(ButtonAction.ACTION_DROP, ctrlIdx) then
        data.ShouldConsumeBomb = not data.ShouldConsumeBomb
    end

    if data.EdithTargetMovementPosition ~= nil then
        data.SlideTarget = data.EdithTargetMovementPosition
    end

    if IsDashing(data) and IsSlideFinished(player, data) then
        data.SlideHitBlacklist = {}
        player:SetMinDamageCooldown(30)
    end

    --- Spawn pepper creep in the tile Edith is moving from
    if data.SlideCounter == 1 then
        -- SpawnPepperCreep(player, 150)

        if IsDashing(data) then
            sfx:Play(SoundEffect.SOUND_SHELLGAME)
        end
    elseif not EdithRestored:IsEdithSliding(data) and data.EdithTargetMovementDirection then
        if data.RamState and data.ExtraIFrames > 0 then
            player:SetMinDamageCooldown(30 + data.ExtraIFrames)
        end
        data.ExtraIFrames = 0
        data.IsInPepper = false
        data.RamState = false
        data.RamGlowCounter = 0
    end

    data.RamState = data.RamState or false

    if not data.RamState then
        local ChargeAdd = EdithRestored:IsEdithSliding(data) and 1 or 2       
        data.SlideCharge = Helpers.Clamp(data.SlideCharge + ChargeAdd, 0, 100)
    end

    if IsDashing(data) then
        local capsule = Capsule(player.Position, Vector.One, 0, 20)

        for _, ent in ipairs(Isaac.FindInCapsule(capsule, EntityPartition.ENEMY)) do
            TriggerDashCollision(player, ent)
        end 
        -- SpawnPepperCreep(player, 150)

        isPressingOppositeDashDirectionKey(player, data)
    end

    if data.SlideCharge >= 100 and Input.IsActionTriggered(ButtonAction.ACTION_BOMB, ctrlIdx) and not EdithRestored:IsEdithSliding(data) then
        data.RamState = true
        data.SlideCharge = 0
        sfx:Play(SoundEffect.SOUND_STONE_IMPACT)
        SetDashColor(player, data)
    end

    if EdithRestored:IsEdithSliding(data) and data.StoppedDash == true then
        player:SetMinDamageCooldown(30)
        EdithRestored:StopSlide(data)
        player.Velocity = Vector.Zero
        data.StoppedDash = false
    end

    local speed = (data.IsInPepper and 10 or 5) + (data.RamState and 10 or 0)
    local grids = data.RamState and 5 or 1

    -- if data.SlideCounter and data.SlideCounter > 0 then
    EdithRestored:EdithGridMovement(player, data, speed, grids)
    -- end
end
EdithRestored:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, Tainted.OnTaintedUpdate)

function Tainted:ChargeBarRender(player)
	local data = EdithRestored:GetData(player)
	if not IsTaintedEdith(player) then return end

    data.SlideCharge = data.SlideCharge or 0

	data.EdithJumpCharge = data.EdithJumpCharge or 0
	data.ChargeBar = data.ChargeBar or Sprite("gfx/chargebar.anm2", true)
	data.ChargeBar.Offset = Vector(-12 * player.SpriteScale.X, -35 * player.SpriteScale.Y)
	HudHelper.RenderChargeBar(
		data.ChargeBar,
		data.SlideCharge,
		100,
		EdithRestored.Room():WorldToScreenPosition(player.Position)
	)
end
EdithRestored:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, Tainted.ChargeBarRender, 0)

---@param player EntityPlayer
function Tainted:OnPEffectUpdate(player)
    local data = EdithRestored:GetData(player)

    if not IsTaintedEdith(player) then return end
    if not data.RamState then return end
    if EdithRestored:IsEdithSliding(data) then return end

    data.RamGlowCounter = data.RamGlowCounter or 0
    data.RamGlowCounter = math.min(data.RamGlowCounter + 1, 15)

    if data.RamGlowCounter == 15 then
        local red = data.ShouldConsumeBomb and 0.3 or 0
        sfx:Play(SoundEffect.SOUND_STONE_IMPACT, 0.25, 0, false, 2)
        player:SetColor(Color(2, 2, 2, 1, red), 5, 100, true, false)
        data.RamGlowCounter = 0
    end
end
EdithRestored:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, Tainted.OnPEffectUpdate)

function Tainted:NegateDashDamage(player)
    local data = EdithRestored:GetData(player)

    if not EdithRestored:IsEdithSliding(data) then return end
    if not data.RamState then return end
    return false
end
EdithRestored:AddCallback(ModCallbacks.MC_PRE_PLAYER_TAKE_DMG, Tainted.NegateDashDamage)

---@param effect EntityEffect
EdithRestored:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, effect)
    if effect.SubType ~= EdithRestored.Enums.Entities.PEPPER_CREEP.SubType then return end

    for _, ent in ipairs(Isaac.FindInRadius(effect.Position, 20 * effect.SpriteScale.X, EntityPartition.PLAYER)) do
        
        local player = ent:ToPlayer() ---@cast player EntityPlayer
        local data = EdithRestored:GetData(player)
        
        if EdithRestored:IsEdithSliding(data) then goto continue end
        data.IsInPepper = true
        ::continue::
    end
end, EdithRestored.Enums.Entities.PEPPER_CREEP.Variant)

---@param npc EntityNPC
---@param source EntityRef
function Tainted:OnEnemyDeath(npc, source)
    if source.Type == 0 then return end

    local player = TSIL.Players.GetPlayerFromEntity(source.Entity) ---@cast player EntityPlayer?

    if not player then return end
    if not IsTaintedEdith(player) then return end
    local data = EdithRestored:GetData(player)

    if IsDashing(data) then return end
    -- SpawnPepperOnGridInRadius(npc, npc.Size + 30)
end 
EdithRestored:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, Tainted.OnEnemyDeath)

---@param player EntityPlayer
---@param index integer
---@param grid GridEntity?
function Tainted:OnDashGridCollision(player, index, grid)
    if not IsTaintedEdith(player) then return end
    if not grid then return end

    local data = EdithRestored:GetData(player)

    if grid:ToPoop() then
        grid:Destroy()
    else
        -- EdithRestored:StopSlide(data)
    end

    player:SetMinDamageCooldown(30)
    -- TriggerDashCollision(player)
end
EdithRestored:AddCallback(ModCallbacks.MC_PLAYER_GRID_COLLISION, Tainted.OnDashGridCollision)

---@param pickup EntityPickup
---@param collider Entity
function Tainted:OnCollectibleCollision(pickup, collider)
    local player = collider:ToPlayer()

    if not player then return end

    local data = EdithRestored:GetData(player)

    EdithRestored:StopSlide(data)
end
EdithRestored:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, Tainted.OnCollectibleCollision, PickupVariant.PICKUP_COLLECTIBLE)
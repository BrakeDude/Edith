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
    return data.RamState and data.ShouldConsumeBomb and PlayerCanUseBombs(player)
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

local function SetDashColor(player, data)
    local red = data.ShouldConsumeBomb and 0.3 or 0
    sfx:Play(SoundEffect.SOUND_STONE_IMPACT, 0.25, 0, false, 2)
    player:SetColor(Color(2, 2, 2, 1, red), 5, 100, true, false)
    data.RamGlowCounter = 0
end 

---@param player EntityPlayer
local function TriggerCollideExplosion(player)
    local data = EdithRestored:GetData(player)

    if not IsBombDash(player, data) then return end

    player:SetMinDamageCooldown(30)

    game:BombExplosionEffects(player.Position, 100, player.TearFlags, Color.Default, player, 1, false, false)

    EdithRestored:StopSlide(data)
    if not player:HasGoldenBomb() then
        player:AddBombs(-1)
    end
    data.RamState = false
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

    sfx:Play(SoundEffect.SOUND_MEATY_DEATHS)

    TriggerCollideExplosion(player)

    player:SetMinDamageCooldown(30)

    if not collider then return end 

    local ptrHash = GetPtrHash(collider)

    if data.SlideHitBlacklist[ptrHash] == true then return end
    if collider.Type == EntityType.ENTITY_STONEY then return end
    if not IsEnemy(collider) then return end

    data.StompDamage = 20
    Helpers.Stomp(player, 1, true, IsBombDash(player, data), true)

    data.SlideHitBlacklist[ptrHash] = true
    data.ExtraIFrames = data.ExtraIFrames or 0
    data.ExtraIFrames = data.ExtraIFrames + 5
    data.SlideHitBlacklist = {}
    
    if collider.HitPoints > data.StompDamage then
        data.RamState = false
        EdithRestored:StopSlide(data)
    end
end

---@param player EntityPlayer
---@param data table
local function IsSlideFinished(player, data)
    if not data.EdithTargetMovementDirection then return false end

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

    data.SlideCharge = data.SlideCharge or 0
    data.Slidespeed = data.Slidespeed or 0
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

    for k, v in pairs(data) do
        -- print(k, v)
    end
    -- print("====================================")

    if IsDashing(data) then
        if data.InputBuffer then
            data.InputBuffer = {}
        end
    end

    if data.RamState and IsSlideFinished(player, data) then
        player:SetMinDamageCooldown(30)
        data.SlideHitBlacklist = {}
        data.RamState = false
    end

    if data.SlideCounter == 1 then
        if IsDashing(data) then
            sfx:Play(SoundEffect.SOUND_SHELLGAME)
        end
    elseif not EdithRestored:IsEdithSliding(data) and data.EdithTargetMovementDirection then
        if data.RamState and data.ExtraIFrames > 0 then
            player:SetMinDamageCooldown(30 + data.ExtraIFrames)
        end
        data.ExtraIFrames = 0
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
    end

    if data.SlideCharge >= 100 and Input.IsActionTriggered(ButtonAction.ACTION_BOMB, ctrlIdx) and not IsDashing(data) then
        data.RamState = true
        data.SlideCharge = 0
        sfx:Play(SoundEffect.SOUND_STONE_IMPACT)
        SetDashColor(player, data)
    end

    local speed = (data.RamState and 18 or 6)
    local grids = data.RamState and 5 or 1

    EdithRestored:EdithGridMovement(player, data, speed, grids)
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

---@param player EntityPlayer
---@param index integer
---@param grid GridEntity?
function Tainted:OnDashGridCollision(player, index, grid)
    if not IsTaintedEdith(player) then return end
    if not grid then return end

    if grid:ToPoop() then
        grid:Destroy()
    else
        local data = EdithRestored:GetData(player)
        EdithRestored:StopSlide(data)
        TriggerCollideExplosion(player)
        data.RamState = false
    end

    player:SetMinDamageCooldown(30)
end
EdithRestored:AddCallback(ModCallbacks.MC_PLAYER_GRID_COLLISION, Tainted.OnDashGridCollision)

---@param collider Entity
function Tainted:OnCollectibleCollision(collider)
    local player = collider:ToPlayer()

    if not player then return end

    local data = EdithRestored:GetData(player)

    EdithRestored:StopSlide(data)
end
EdithRestored:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, Tainted.OnCollectibleCollision, PickupVariant.PICKUP_COLLECTIBLE)

---@param player EntityPlayer
---@param collider Entity
function Tainted:OnPlayerCollision(player, collider)
    if not IsTaintedEdith(player) then return end
    if not Helpers.IsEnemy(collider) then return end

    local data = EdithRestored:GetData(player)

    if data.RamState and collider.HitPoints > data.StompDamage then
        data.RamState = false
        EdithRestored:StopSlide(data)
        player.Velocity = (player.Position - collider.Position):Normalized() 
    end
    EdithRestored:StopSlide(data)
end 
EdithRestored:AddCallback(ModCallbacks.MC_PRE_PLAYER_COLLISION, Tainted.OnPlayerCollision)

function Tainted:ResetRamStateOnNewRoom()
    for _, player in ipairs(PlayerManager.GetPlayers()) do
        if IsTaintedEdith(player) then
            local data = EdithRestored:GetData(player)
            
            EdithRestored:StopSlide(data)
            data.RamState = false
        end
    end
end
EdithRestored:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, Tainted.ResetRamStateOnNewRoom)

function Tainted:edith_Stats(player, cacheFlag)
	if IsTaintedEdith(player) then -- If the player is Edith it will apply her specific stats
		if cacheFlag == CacheFlag.CACHE_DAMAGE then
			player.Damage = player.Damage * 1.1
		end
	--e3	Helpers.ChangePepperValue(player)
	end
	-- if cacheFlag == CacheFlag.CACHE_SPEED and Helpers.IsPlayerEdith(player) 
	-- and not EdithRestored.Room():HasCurseMist() then
	-- 	player.MoveSpeed = math.max(0.3, player.MoveSpeed)
	-- end
end
EdithRestored:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, Tainted.edith_Stats)

---@param player EntityPlayer
---@param damage number
function Tainted:OverrideStompParams(player, damage)
    if not IsTaintedEdith(player) then return end

    return {StompDamage = damage + 3}
end 
EdithRestored:AddCallback(EdithRestored.Enums.Callbacks.ON_EDITH_MODIFY_STOMP, Tainted.OverrideStompParams)
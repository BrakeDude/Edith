---@diagnostic disable: need-check-nil
local Helpers = EdithRestored.Helpers
local game = EdithRestored.Game
local sfx = EdithRestored.SFX
local Tainted = {}

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

---@param tear EntityTear
local function ChangeToEdithTear(tear)
	tear:ChangeVariant(TearVariant.ROCK)

	local tearColor = tear.Color
	local parentColor = tear.Parent.Color

	tear.Color = Color(
		tearColor.R - 0.4 + (parentColor.R - 1),
		tearColor.G - 0.35 + (parentColor.G - 1),
		tearColor.B - 0.35 + (parentColor.B - 1),
		tearColor.A + (parentColor.A - 1),
		tearColor.RO + parentColor.RO,
		tearColor.GO + parentColor.GO,
		tearColor.BO + parentColor.BO
	)
end

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
function Tainted:OnEdithFireTear(tear)
	local player = TSIL.Players.GetPlayerFromEntity(tear)

	if not player then return end
	if not IsTaintedEdith(player) or player:HasCurseMistEffect() or TearsToNotChange(tear) then return end

	ChangeToEdithTear(tear)
	tear.Scale = tear.Scale * 0.9
	tear.SpriteScale = tear.SpriteScale * 0.9
end

EdithRestored:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, Tainted.OnEdithFireTear)


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
---@param data table
local function ManageTEdithDashCollide(player, data, collider)
    local colPtrHash = GetPtrHash(collider)

    if not data.RamState then return end
    if data.SlideHitBlacklist[colPtrHash] then return end

    local isBombDash = IsBombDash(player, data)

    Helpers.Stomp(player, 1, true, isBombDash, true)
    data.SlideHitBlacklist[colPtrHash] = true

    if isBombDash and not player:HasGoldenBomb() then
        player:AddBombs(-1)
    end

    if collider.HitPoints > data.StompDamage then
        data.RamState = false
        EdithRestored:StopSlide(data)
    end

    player:SetMinDamageCooldown(30)
end

---@param player EntityPlayer
---@param collider Entity
function Tainted:OnPlayerCollision(player, collider)
    if not IsTaintedEdith(player) then return end
    if not Helpers.IsEnemy(collider) then return end
    
    local data = EdithRestored:GetData(player)

    ManageTEdithDashCollide(player, data, collider)

    if not data.RamState then
        EdithRestored:StopSlide(data)
    end
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
---@param radius number
function Tainted:OverrideStompParams(player, damage, radius)
    if not IsTaintedEdith(player) then return end

    return {StompDamage = damage + 3, radius = 30}
end 
EdithRestored:AddCallback(EdithRestored.Enums.Callbacks.ON_EDITH_MODIFY_STOMP, Tainted.OverrideStompParams)
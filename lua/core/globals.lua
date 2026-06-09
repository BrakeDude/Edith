local game = Game()
EdithRestored.Game = game
EdithRestored.Level = game:GetLevel()

EdithRestored.Room = function()
	return game:GetRoom()
end

local runData = {
	["UsedDataMiner"] = false,
	["MoonPhase"] = 1,
	["MoonPhaseWolf"] = false,
}

EdithRestored.DebugMode = false
local DebugModeValues = {
	--Edith
	StompRadius = 65,
	InstantJumpCharge = true,
	JumpHeight = 4,
	Gravity = 0.7,
	IFrames = 30,
	UseIFrames = false,
	IgnoreStompDamage = false,
	--Peppermint
	PeppermintCharge = 210,
	PeppermintCloudSize = XMLData.GetEntryByName(XMLNode.ENTITY, "Peppermint Cloud").collisionradius,
	PeppermintCloudPosOffsetX = 0,
	PeppermintCloudPosOffsetY = -25,
	PeppermintCloudSizeXMult = 1,
	PeppermintCloudSizeYMult = 1,
	--Misc
	BlastingBootsCd = 150,
	BlastingBootsDisable = false,
	--Red Hood
	AlwaysRedMoon = false,
	DisableMoonProgression = false,
	AlwaysShowMoonPhase = false,
}

local DebugModeValuesDefault = {
	--Edith
	StompRadius = 65,
	InstantJumpCharge = true,
	JumpHeight = 4,
	Gravity = 0.7,
	IFrames = 30,
	UseIFrames = false,
	IgnoreStompDamage = false,
	--Peppermint
	PeppermintCharge = 210,
	PeppermintCloudSize = XMLData.GetEntryByName(XMLNode.ENTITY, "Peppermint Cloud").collisionradius,
	PeppermintCloudPosOffsetX = 0,
	PeppermintCloudPosOffsetY = -25,
	PeppermintCloudSizeXMult = 1,
	PeppermintCloudSizeYMult = 1,
	--Misc
	BlastingBootsCd = 150,
	BlastingBootsDisable = false,
	--Red Hood
	AlwaysRedMoon = false,
	DisableMoonProgression = false,
	AlwaysShowMoonPhase = false,
}

EdithRestored.SaveManager.Utility.AddDefaultRunData(EdithRestored.SaveManager.DefaultSaveKeys.GLOBAL, runData)

EdithRestored:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
	for _, bomb in ipairs(Isaac.FindByType(EntityType.ENTITY_BOMB)) do
		EdithRestored:GetData(bomb).BombInit = true
	end
end)

---@param message string
---@param logFile boolean?
function EdithRestored:Log(message, logFile)
	print(message)
	if type(logFile) == "boolean" and logFile == true then
		Isaac.DebugString(message)
	end
end

---@type table[]
local getData = {}

---Slightly faster than calling GetData, a micromanagement at best
---
---However GetData() is wiped on POST_ENTITY_REMOVE, so this also helps retain the data until after entity removal
---@param ent Entity
---@return table
function EdithRestored:GetData(ent)
	if not ent then
		return {}
	end
	local ptrHash = GetPtrHash(ent)
	local data = getData[ptrHash]
	if not data then
		local newData = {}
		getData[ptrHash] = newData
		data = newData
	end
	return data
end

---@param ent Entity
---@return table?
function EdithRestored:TryGetData(ent)
	local ptrHash = GetPtrHash(ent)
	local data = getData[ptrHash]
	return data
end

EdithRestored:AddPriorityCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, CallbackPriority.LATE, function(_, ent)
	getData[GetPtrHash(ent)] = nil
end)

---@param key string
---@return integer | boolean?
function EdithRestored:GetDebugValue(key)
	if EdithRestored.DebugMode then
		if DebugModeValues[key] ~= nil then
			return DebugModeValues[key]
		else
			EdithRestored:Log("Value "..key.." doesn't exist.")
		end
	end
end

---@param key string
---@param value number | boolean
function EdithRestored:SetDebugValue(key, value)
	if EdithRestored.DebugMode then
		if DebugModeValues[key] ~= nil then
			DebugModeValues[key] = value
		else
			EdithRestored:Log("Value "..key.." doesn't exist.")
		end
	end
end

---@param key string
function EdithRestored:SetDefaultDebugValue(key)
	if EdithRestored.DebugMode then
		if DebugModeValues[key] ~= nil then
			DebugModeValues[key] = DebugModeValuesDefault[key]
		else
			EdithRestored:Log("Value "..key.." doesn't exist.")
		end
	end
end
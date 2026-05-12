function EdithRestored:GameSave()
	return EdithRestored.SaveManager.GetPersistentSave()
end

function EdithRestored:RunSave(ent, noHourglass, allowSoulSave)
    return EdithRestored.SaveManager.GetRunSave(ent, noHourglass, allowSoulSave)
end

function EdithRestored:FloorSave(ent, noHourglass, allowSoulSave)
    return EdithRestored.SaveManager.GetFloorSave(ent, noHourglass, allowSoulSave)
end

function EdithRestored:RoomSave(ent, noHourglass, gridIndex, allowSoulSave)
    return EdithRestored.SaveManager.GetRoomSave(ent, noHourglass, gridIndex, allowSoulSave)
end

function EdithRestored:AddDefaultFileSave(key, value)
    EdithRestored:GameSave()[key] = value
end

function EdithRestored:GetDefaultFileSave(key)
    if EdithRestored.SaveManager.Utility.IsDataInitialized() then
        return EdithRestored:GameSave()[key]
    end
end

EdithRestored:AddCallback(EdithRestored.SaveManager.SaveCallbacks.PRE_DATA_LOAD, function(_, data, luaMod)
	if not luaMod then
        local settings = {
            ["OnlyStomps"] = false,
            ["TargetColor"] = {R = 155, G = 0, B = 0},
            ["AllowHolding"] = true,
            ["DisabledItems"] = {},
            ["DisabledTrinkets"] = {},
            ["ElectrifierCharges"] = 0,
		}
		for k,v in pairs(settings) do
			if data.file.other[k] == nil then
				data.file.other[k] = v
			end
		end
		return data
	end
end)
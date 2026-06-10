local function InitSounds()
    if USoEI then
        local itemConfig = EdithRestored.ItemConfig
        for _,collectible in pairs(EdithRestored.Enums.CollectibleType) do
            local collectibleConf = itemConfig:GetCollectible(collectible)
            if collectibleConf then
                local sound = Isaac.GetSoundIdByName(collectibleConf.Name)
                if sound > 0 then
                    USoEI.AddSoundToItem(collectible, sound)
                end
            end
        end
    end
end
EdithRestored:AddCallback(ModCallbacks.MC_POST_MODS_LOADED, InitSounds)

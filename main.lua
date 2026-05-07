---@class ModReference
EdithRestored = RegisterMod("Edith", 1)

--#region mod error message, thanks Mr. Fly6
local isRepentance, isRepentogon = REPENTANCE_PLUS or REPENTANCE, (REPENTOGON or _G._VERSION == "Lua 5.4")
local errMessage = ""
local modName = EdithRestored.Name
local function GetScreenSize()
	return Vector(Isaac.GetScreenWidth(), Isaac.GetScreenHeight())
end

if not isRepentance or not isRepentogon then
	if not isRepentance then
		errMessage = modName .. " " .. "mod requires Repentance DLC to work"
	elseif not isRepentogon then
		errMessage = modName
			.. " "
			.. "mod requires Repentogon Script Extender to work. Head to https://repentogon.com/"
	end

	local transparency = 0
	EdithRestored:AddCallback(ModCallbacks.MC_POST_RENDER, function()
		if transparency > 0 then
			transparency = transparency - 1
			local a = transparency / 120
			if a > 1 then
				a = 1
			end
			local screenSize = GetScreenSize()
			Isaac.RenderScaledText(errMessage, screenSize.X / 5, screenSize.Y / 3, 0.5, 0.5, 1, 0, 0, a)
		end
	end)

	EdithRestored:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, continue)
		if not continue then
			transparency = 600
		end
	end)

	local eType = Isaac.GetPlayerTypeByName("Redith", false)

    EdithRestored:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function(_, player)
        if player:GetPlayerType() == eType then
			player:ChangePlayerType(PlayerType.PLAYER_ISAAC)
		end
    end)
    
	return
end
--#endregion

local LOCAL_TSIL = require("lua.extraLibs.loi.TSIL")
LOCAL_TSIL.Init("lua.extraLibs.loi")
include("lua.extraLibs.APIs.custom_bomb_flags")

require("lua.extraLibs.jumplib").Init()
include("lua.extraLibs.hud_helper")

EdithRestored.SaveManager = include("lua.core.save_manager")
EdithRestored.SaveManager.Init(EdithRestored)
include("lua.core.saving_system")

--core
include("lua.core.enums")
include("lua.core.globals")
include("lua.helpers.Helpers")
include("lua.core.achievements")
include("lua.core.dss.deadseascrolls")
include("lua.core.BlockDisabledItems")

--entities
include("lua.entities.player.main")
--include("lua.entities.player.tainted")
include("lua.entities.clots.main")
--include("lua.entities.slots.main")

--items
--active
include("lua.items.active.GorgonMask.main")
include("lua.items.active.SaltShaker.main")

--passive
include("lua.items.passive.Lithium.main")
include("lua.items.passive.Sodom.main")
include("lua.items.passive.BlastingBoots.main")
include("lua.items.passive.SaltyBaby.main")
include("lua.items.passive.SaltPawns.main")
include("lua.items.passive.ThunderBombs.main")

include("lua.items.passive.RedHood.main")
include("lua.items.passive.ShrapnelBombs.main")
include("lua.items.passive.Peppermint.main")

-- trinkets
include("lua.items.trinkets.PepperGrinder.main")
include("lua.items.trinkets.SaltRock.main")
include("lua.items.trinkets.SmellingSalts.main")
include("lua.items.trinkets.ChunkOfAmber.main")

-- cards
include("lua.items.cards.SoulOfEdith.main")
--include("lua.items.cards.Prudence.main")
--include("lua.items.cards.PrudenceReverse.main")

-- challenges
include("lua.challenges.rocket_laces")

--mod compatibility
include("lua.mod_compat.main")

--misc
include("lua.items.funny")

--stomp synergies
include("lua.entities.player.SynergiesCallbacks")

if StageAPI and StageAPI.Loaded then
	StageAPI.AddPlayerGraphicsInfo(EdithRestored.Enums.PlayerType.EDITH, {
		Name = "gfx/ui/boss/playername_Edith.png",
		Portrait = "gfx/ui/boss/playerportrait_Edith_A.png",
		NoShake = true,
	})

	--[[StageAPI.AddPlayerGraphicsInfo(EdithRestored.Enums.PlayerType.EDITH_B, {
        Name = "gfx/ui/boss/playername_Edith.png",
        Portrait = "gfx/ui/boss/playerportrait_Edith_B.png",
        NoShake = true
    })]]
end

EdithRestored:Log("Edith Restored loaded.")

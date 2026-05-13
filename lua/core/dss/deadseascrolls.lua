local DSSModName = "Dead Sea Scrolls (Edith Restored)"

local DSSCoreVersion = 7

local pgd = Isaac.GetPersistentGameData()

local modMenuName = "Edith Restored"
-- Those functions were taken from Balance Mod, just to make things easier
local BREAK_LINE = { str = "", fsize = 1, nosel = true }

local orderedItems = {}
local orderedTrinkets = {}
local itemConfig = Isaac.GetItemConfig()
local itemPool = Game():GetItemPool()

for _, blacklist in ipairs({
	{
		Table = orderedItems,
		LookupTable = EdithRestored.Enums.CollectibleType,
		Func = itemConfig.GetCollectible,
	},
	{
		Table = orderedTrinkets,
		LookupTable = EdithRestored.Enums.TrinketType,
		Func = itemConfig.GetTrinket,
	},
}) do
	for _, item in pairs(blacklist.LookupTable) do
		local itemConf = blacklist.Func(itemConfig, item)
		if itemConf then
			blacklist.Table[#blacklist.Table + 1] = itemConf
		end
	end
	table.sort(blacklist.Table, function(a, b)
		return a.Name < b.Name
	end)
end

local function GenerateTooltip(str)
	local endTable = {}
	local currentString = ""
	for w in str:gmatch("%S+") do
		local newString = currentString .. w .. " "
		if newString:len() >= 15 then
			table.insert(endTable, currentString)
			currentString = ""
		end

		currentString = currentString .. w .. " "
	end

	table.insert(endTable, currentString)
	return { strset = endTable }
end
-- Thanks to catinsurance for those functions

-- Every MenuProvider function below must have its own implementation in your mod, in order to handle menu save data.
local MenuProvider = {}

function MenuProvider.SaveSaveData()
	EdithRestored.SaveManager.Save()
end

function MenuProvider.GetPaletteSetting()
	local dssSave = EdithRestored.SaveManager.GetDeadSeaScrollsSave()
	return dssSave and dssSave.MenuPalette or nil
end

function MenuProvider.SavePaletteSetting(var)
	local dssSave = EdithRestored.SaveManager.GetDeadSeaScrollsSave()
	dssSave.MenuPalette = var
end

function MenuProvider.GetGamepadToggleSetting()
	local dssSave = EdithRestored.SaveManager.GetDeadSeaScrollsSave()
	return dssSave and dssSave.GamepadToggle or nil
end

function MenuProvider.SaveGamepadToggleSetting(var)
	local dssSave = EdithRestored.SaveManager.GetDeadSeaScrollsSave()
	dssSave.GamepadToggle = var
end

function MenuProvider.GetMenuKeybindSetting()
	local dssSave = EdithRestored.SaveManager.GetDeadSeaScrollsSave()
	return dssSave and dssSave.MenuKeybind or nil
end

function MenuProvider.SaveMenuKeybindSetting(var)
	local dssSave = EdithRestored.SaveManager.GetDeadSeaScrollsSave()
	dssSave.MenuKeybind = var
end

function MenuProvider.GetMenuHintSetting()
	local dssSave = EdithRestored.SaveManager.GetDeadSeaScrollsSave()
	return dssSave and dssSave.MenuHint or nil
end

function MenuProvider.SaveMenuHintSetting(var)
	local dssSave = EdithRestored.SaveManager.GetDeadSeaScrollsSave()
	dssSave.MenuHint = var
end

function MenuProvider.GetMenuBuzzerSetting()
	local dssSave = EdithRestored.SaveManager.GetDeadSeaScrollsSave()
	return dssSave and dssSave.MenuBuzzer or nil
end

function MenuProvider.SaveMenuBuzzerSetting(var)
	local dssSave = EdithRestored.SaveManager.GetDeadSeaScrollsSave()
	dssSave.MenuBuzzer = var
end

function MenuProvider.GetMenusNotified()
	local dssSave = EdithRestored.SaveManager.GetDeadSeaScrollsSave()
	return dssSave and dssSave.MenusNotified or nil
end

function MenuProvider.SaveMenusNotified(var)
	local dssSave = EdithRestored.SaveManager.GetDeadSeaScrollsSave()
	dssSave.MenusNotified = var
end

function MenuProvider.GetMenusPoppedUp()
	local dssSave = EdithRestored.SaveManager.GetDeadSeaScrollsSave()
	return dssSave and dssSave.MenusPoppedUp or nil
end

function MenuProvider.SaveMenusPoppedUp(var)
	local dssSave = EdithRestored.SaveManager.GetDeadSeaScrollsSave()
	dssSave.MenusPoppedUp = var
end

local function ShowTogglesButton(t)
	local isTrinket = t:lower() == "trinkets"
	local lookupTable = isTrinket and EdithRestored.Enums.TrinketType or EdithRestored.Enums.CollectibleType
	for name, id in pairs(lookupTable) do
		local itemConf = isTrinket and itemConfig:GetTrinket(id) or itemConfig:GetCollectible(id)
		if itemConf then
			if itemConf.AchievementID == -1 or pgd:Unlocked(itemConf.AchievementID) then
				return true
			end
		end
	end
	return false
end
local DSSInitializerFunction = include("lua.core.dss.dssmenucore")

-- This function returns a table that some useful functions and defaults are stored on
local dssmod = DSSInitializerFunction(DSSModName, DSSCoreVersion, MenuProvider)

local function GetItemsEnum(id)
	for enum, collectible in pairs(EdithRestored.Enums.CollectibleType) do
		if id == collectible then
			return enum
		end
	end
	return ""
end

local function GetTrinketsEnum(id)
	for enum, trinket in pairs(EdithRestored.Enums.TrinketType) do
		if id == trinket then
			return enum
		end
	end
	return ""
end

local function SplitStr(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t = {}
	for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
		table.insert(t, str)
	end
	return t
end

local function RemoveZeroWidthSpace(str)
	if str:sub(1, 3) == "​" then
		str = str:sub(4, str:len())
	end
	return str
end

local function InitDisableMenu(t)
	local itemTogglesMenu = {}
	itemTogglesMenu = {
		{ str = "choose which " .. t, fsize = 2, nosel = true },
		{ str = "show up", fsize = 2, nosel = true },
		{ str = "(disabled - in blacklist)", fsize = 2, nosel = true },
		{ str = "", fsize = 2, nosel = true },
	}

	local lookupTable = EdithRestored.Enums.CollectibleType
	local blackList = "DisabledItems"
	local enumFunc = GetItemsEnum
	local orderedTable = orderedItems

	if t == "trinkets" then
		lookupTable = EdithRestored.Enums.TrinketType
		blackList = "DisabledTrinkets"
		enumFunc = GetTrinketsEnum
		orderedTable = orderedTrinkets
	end

	for _, itemConf in pairs(orderedTable) do
		local split = SplitStr(string.lower(RemoveZeroWidthSpace(itemConf.Name)))

		local tooltipStr = { "enable", "" }
		for _, word in ipairs(split) do
			if tooltipStr[#tooltipStr]:len() + word:len() > 15 then
				tooltipStr[#tooltipStr] = tooltipStr[#tooltipStr]:sub(0, tooltipStr[#tooltipStr]:len() - 1)
				tooltipStr[#tooltipStr + 1] = word .. " "
			else
				tooltipStr[#tooltipStr] = tooltipStr[#tooltipStr] .. word .. " "
			end
		end
		tooltipStr[#tooltipStr] = tooltipStr[#tooltipStr]:sub(0, tooltipStr[#tooltipStr]:len() - 1)

		local itemSprite = Sprite()
		itemSprite:Load("gfx/ui/dss_item.anm2", false)
		itemSprite:ReplaceSpritesheet(0, itemConf.GfxFileName)
		itemSprite:LoadGraphics()
		itemSprite:SetFrame("Idle", 0)

		local itemOption = {
			str = string.lower(RemoveZeroWidthSpace(itemConf.Name)),

			-- The "choices" tag on a button allows you to create a multiple-choice setting
			choices = { "enabled", "disabled" },
			-- The "setting" tag determines the default setting, by list index. EG "1" here will result in the default setting being "choice a"
			setting = 1,

			-- "variable" is used as a key to story your setting; just set it to something unique for each setting!
			variable = "Toggle" .. t .. itemConf.Name,

			-- When the menu is opened, "load" will be called on all settings-buttons
			-- The "load" function for a button should return what its current setting should be
			-- This generally means looking at your mod's save data, and returning whatever setting you have stored
			load = function()
				for indexItem, disabledItem in pairs(EdithRestored:GetDefaultFileSave(blackList)) do
					if lookupTable[indexItem] == itemConf.ID then
						return 2
					end
				end
				return 1
			end,

			-- When the menu is closed, "store" will be called on all settings-buttons
			-- The "store" function for a button should save the button's setting (passed in as the first argument) to save data!
			store = function(var)
				local disabledItems = EdithRestored:GetDefaultFileSave(blackList)
				for indexItem, disabledItem in pairs(disabledItems) do
					if lookupTable[indexItem] == itemConf.ID then
						if var == 1 then
							disabledItems[indexItem] = nil
							itemConf.Hidden = false
							if itemConf:IsTrinket() then
								EdithRestored.Helpers:AddTrinketToPool(itemConf.ID)
							end
						end
						break
					end
				end

				if var == 2 then
					disabledItems[enumFunc(itemConf.ID)] = true
					itemConf.Hidden = true
					if itemConf:IsTrinket() then
						itemPool:RemoveTrinket(itemConf.ID)
					end
				end
				EdithRestored.SaveManager.Save()
			end,
			displayif = function()
				return itemConf.AchievementID == -1 or pgd:Unlocked(itemConf.AchievementID)
			end,
			-- A simple way to define tooltips is using the "strset" tag, where each string in the table is another line of the tooltip
			tooltip = {
				buttons = {
					{
						spr = {
							sprite = itemSprite,
							centerx = 16,
							centery = 16,
							width = 32,
							height = 32,
							float = { 1, 6 },
							shadow = true,
							nosel = true,
						},
					},
					{ strset = tooltipStr },
				},
			},
		}

		itemTogglesMenu[#itemTogglesMenu + 1] = itemOption
	end

	return itemTogglesMenu
end

local function InitDisableItemMenu()
	return InitDisableMenu("items")
end

local function InitDisableTrinketMenu()
	return InitDisableMenu("trinkets")
end

local function InitTargetColorMenu()
	local targetColorMenu = {
		{
			str = "red",

			-- If "min" and "max" are set without "slider", you've got yourself a number option!
			-- It will allow you to scroll through the entire range of numbers from "min" to "max", incrementing by "increment"
			min = 0,
			max = 255,
			increment = 1,

			-- You can also specify a prefix or suffix that will be applied to the number, which is especially useful for percentages!
			--pref = 'hi! ',
			setting = 155,

			variable = "TargetColorRed",

			load = function()
				return EdithRestored:GetDefaultFileSave("TargetColor").R or 155
			end,
			store = function(newOption)
				EdithRestored:GetDefaultFileSave("TargetColor").R = newOption
				EdithRestored.SaveManager.Save()
			end,

			tooltip = GenerateTooltip("color red value"),
		},
		{
			str = "green",

			-- If "min" and "max" are set without "slider", you've got yourself a number option!
			-- It will allow you to scroll through the entire range of numbers from "min" to "max", incrementing by "increment"
			min = 0,
			max = 255,
			increment = 1,

			-- You can also specify a prefix or suffix that will be applied to the number, which is especially useful for percentages!
			--pref = 'hi! ',
			setting = 155,

			variable = "TargetColorGreen",

			load = function()
				return EdithRestored:GetDefaultFileSave("TargetColor").G or 0
			end,
			store = function(newOption)
				EdithRestored:GetDefaultFileSave("TargetColor").G = newOption
				EdithRestored.SaveManager.Save()
			end,

			tooltip = GenerateTooltip("color green value"),
		},
		{
			str = "blue",

			-- If "min" and "max" are set without "slider", you've got yourself a number option!
			-- It will allow you to scroll through the entire range of numbers from "min" to "max", incrementing by "increment"
			min = 0,
			max = 255,
			increment = 1,

			-- You can also specify a prefix or suffix that will be applied to the number, which is especially useful for percentages!
			--pref = 'hi! ',
			setting = 155,

			variable = "TargetColorBlue",

			load = function()
				return EdithRestored:GetDefaultFileSave("TargetColor").B or 0
			end,
			store = function(newOption)
				EdithRestored:GetDefaultFileSave("TargetColor").B = newOption
				EdithRestored.SaveManager.Save()
			end,

			tooltip = GenerateTooltip("color blue value"),
		},
	}
	return targetColorMenu
end

-- Creating a menu like any other DSS menu is a simple process.
-- You need a "Directory", which defines all of the pages ("items") that can be accessed on your menu, and a "DirectoryKey", which defines the state of the menu.
local edithdirectory = {
	-- The keys in this table are used to determine button destinations.
	main = {
		-- "title" is the big line of text that shows up at the top of the page!
		title = "edith restored",

		-- "buttons" is a list of objects that will be displayed on this page. The meat of the menu!
		buttons = {
			-- The simplest button has just a "str" tag, which just displays a line of text.

			-- The "action" tag can do one of three pre-defined actions:
			--- "resume" closes the menu, like the resume game button on the pause menu. Generally a good idea to have a button for this on your main page!
			--- "back" backs out to the previous menu item, as if you had sent the menu back input
			--- "openmenu" opens a different dss menu, using the "menu" tag of the button as the name
			{ str = "resume game", action = "resume" },

			-- The "dest" option, if specified, means that pressing the button will send you to that page of your menu.
			-- If using the "openmenu" action, "dest" will pick which item of that menu you are sent to.
			{ str = "settings", dest = "settings" },

			{
				str = "items toggles",
				dest = "items",
				displayif = function()
					return ShowTogglesButton("items")
				end,
			},
			{
				str = "trinkets toggles",
				dest = "trinkets",
				displayif = function()
					return ShowTogglesButton("trinkets")
				end,
			},
			-- A few default buttons are provided in the table returned from DSSInitializerFunction.
			-- They're buttons that handle generic menu features, like changelogs, palette, and the menu opening keybind
			-- They'll only be visible in your menu if your menu is the only mod menu active; otherwise, they'll show up in the outermost Dead Sea Scrolls menu that lets you pick which mod menu to open.
			-- This one leads to the changelogs menu, which contains changelogs defined by all mods.
			dssmod.changelogsButton,
		},
		-- A tooltip can be set either on an item or a button, and will display in the corner of the menu while a button is selected or the item is visible with no tooltip selected from a button.
		-- The object returned from DSSInitializerFunction contains a default tooltip that describes how to open the menu, at "menuOpenToolTip"
		-- It's generally a good idea to use that one as a default!
		tooltip = dssmod.menuOpenToolTip,
	},
	items = {
		title = "items toggles",
		buttons = InitDisableItemMenu(),
	},
	trinkets = {
		title = "trinkets toggles",
		buttons = InitDisableTrinketMenu(),
	},
	targetcolor = {
		title = "target color",
		buttons = InitTargetColorMenu(),
	},
	settings = {
		title = "settings",
		buttons = {
			{ str = "", nosel = true },
			{
				strset = { "slide", "on hold button" },
				choices = { "enable", "disable" },
				setting = 1,
				variable = "AllowHolding",

				load = function()
					return EdithRestored:GetDefaultFileSave("AllowHolding") and 1 or 2
				end,

				store = function(newOption)
					EdithRestored:AddDefaultFileSave("AllowHolding", newOption == 1)
					EdithRestored.SaveManager.Save()
				end,

				tooltip = GenerateTooltip("enable or disable the sliding on holding a movement button"),
			},
			{
				str = "",
				fsize = 2,
				nosel = true,
			},
			{
				strset = { "bombs", "for edith" },
				choices = { "enable", "disable" },
				setting = 1,
				variable = "OnlyStomps",

				load = function()
					return EdithRestored:GetDefaultFileSave("OnlyStomps") and 1 or 2
				end,

				store = function(newOption)
					EdithRestored:AddDefaultFileSave("OnlyStomps", newOption == 1)
					EdithRestored.SaveManager.Save()
				end,

				tooltip = GenerateTooltip("enable or disable placing bombs when playing as edith"),
			},
			{
				str = "",
				fsize = 2,
				nosel = true,
			},
			{
				str = "target color",
				dest = "targetcolor",
				tooltip = GenerateTooltip("edith target color customization"),
			},
			{
				str = "",
				fsize = 2,
				nosel = true,
			},
			{
				str = "",
				fsize = 2,
				nosel = true,
			},
			dssmod.gamepadToggleButton,
			dssmod.menuKeybindButton,
			dssmod.paletteButton,
			dssmod.menuHintButton,
			dssmod.menuBuzzerButton,
		},
	},
}

local edithdirectorykey = {
	Item = edithdirectory.main, -- This is the initial item of the menu, generally you want to set it to your main item
	Main = "main", -- The main item of the menu is the item that gets opened first when opening your mod's menu.

	-- These are default state variables for the menu; they're important to have in here, but you don't need to change them at all.
	Idle = false,
	MaskAlpha = 1,
	Settings = {},
	SettingsChanged = false,
	Path = {},
}

--#region AgentCucco pause manager for DSS
local function DeleteParticles()
	for _, ember in ipairs(Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.FALLING_EMBER, -1)) do
		if ember:Exists() then
			ember:Remove()
		end
	end
	if REPENTANCE then
		for _, rain in ipairs(Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.RAIN_DROP, -1)) do
			if rain:Exists() then
				rain:Remove()
			end
		end
	end
end

local OldTimer
local OldTimerBossRush
local OldTimerHush
local OverwrittenPause = false
local AddedPauseCallback = false
local function OverridePause(self, player, hook, action)
	if not AddedPauseCallback then
		return nil
	end

	if OverwrittenPause then
		OverwrittenPause = false
		AddedPauseCallback = false
		return
	end

	if action == ButtonAction.ACTION_SHOOTRIGHT then
		OverwrittenPause = true
		DeleteParticles()
		return true
	end
end
EdithRestored:AddCallback(ModCallbacks.MC_INPUT_ACTION, OverridePause, InputHook.IS_ACTION_PRESSED)

local function FreezeGame(unfreeze)
	if unfreeze then
		OldTimer = nil
		OldTimerBossRush = nil
		OldTimerHush = nil
		if not AddedPauseCallback then
			AddedPauseCallback = true
		end
	else
		if not OldTimer then
			OldTimer = Game().TimeCounter
		end
		if not OldTimerBossRush then
			OldTimerBossRush = Game().BossRushParTime
		end
		if not OldTimerHush then
			OldTimerHush = Game().BlueWombParTime
		end

		Isaac.GetPlayer(0):UseActiveItem(CollectibleType.COLLECTIBLE_PAUSE, UseFlag.USE_NOANIM)
		if REPENTANCE_PLUS then
			SFXManager():Stop(SoundEffect.SOUND_PAUSE_FREEZE)
		end

		Game().TimeCounter = OldTimer
		Game().BossRushParTime = OldTimerBossRush
		Game().BlueWombParTime = OldTimerHush
		DeleteParticles()
	end
end

local function RunEdithDSSMenu(tbl)
	FreezeGame()
	dssmod.runMenu(tbl)
end

local function CloseEdithDSSMenu(tbl, fullClose, noAnimate)
	FreezeGame(true)
	dssmod.closeMenu(tbl, fullClose, noAnimate)
end

--#endregion
DeadSeaScrollsMenu.AddMenu(modMenuName, {
	-- The Run, Close, and Open functions define the core loop of your menu
	-- Once your menu is opened, all the work is shifted off to your mod running these functions, so each mod can have its own independently functioning menu.
	-- The DSSInitializerFunction returns a table with defaults defined for each function, as "runMenu", "openMenu", and "closeMenu"
	-- Using these defaults will get you the same menu you see in Bertran and most other mods that use DSS
	-- But, if you did want a completely custom menu, this would be the way to do it!

	-- This function runs every render frame while your menu is open, it handles everything! Drawing, inputs, etc.
	Run = RunEdithDSSMenu,
	-- This function runs when the menu is opened, and generally initializes the menu.
	Open = dssmod.openMenu,
	-- This function runs when the menu is closed, and generally handles storing of save data / general shut down.
	Close = CloseEdithDSSMenu,

	Directory = edithdirectory,
	DirectoryKey = edithdirectorykey,
})

include("lua.core.dss.changelog")
-- There are a lot more features that DSS supports not covered here, like sprite insertion and scroller menus, that you'll have to look at other mods for reference to use.
-- But, this should be everything you need to create a simple menu for configuration or other simple use cases!

--imgui

local function RemoveTogglesItems(t)
	local orderedTable = t == "Trinkets" and orderedTrinkets or orderedItems
	for _, itemConf in pairs(orderedTable) do
		local elemName = "edithRestoredToggles"..t..string.gsub(itemConf.Name, " ", "")
		if ImGui.ElementExists(elemName) then
			ImGui.RemoveCallback(elemName, ImGuiCallback.Render)
			ImGui.RemoveElement(elemName)
		end
	end
end

local function ReOrederItems(t)
	local i = 0

    local orderedTable = orderedItems
    local lookupTable = EdithRestored.Enums.CollectibleType
    local enumFunc = GetItemsEnum
    local toggles = "DisabledItems"

    if t == "Trinkets" then
        orderedTable = orderedTrinkets
        lookupTable = EdithRestored.Enums.TrinketType
        enumFunc = GetTrinketsEnum
        toggles = "DisabledTrinkets"
    end

	RemoveTogglesItems(t)
	for _, itemConf in pairs(orderedTable) do
		local elemName = "edithRestoredToggles"..t..string.gsub(itemConf.Name, " ", "")
		if itemConf.AchievementID == -1 or pgd:Unlocked(itemConf.AchievementID) then
			i = i + 1
			ImGui.AddCheckbox(
				"edithWindowToggles"..t,
				elemName,
				RemoveZeroWidthSpace(itemConf.Name),
				function(val)
					local disabledItems = EdithRestored:GetDefaultFileSave(toggles)
					for indexItem, disabledItem in pairs(disabledItems) do
						if lookupTable[indexItem] == itemConf.ID then
							if val then
								disabledItems[indexItem] = nil
								itemConf.Hidden = false
								if itemConf:IsTrinket() then
									EdithRestored.Helpers:AddTrinketToPool(itemConf.ID)
								end
							end
							break
						end
					end

					if not val then
                        disabledItems[enumFunc(itemConf.ID)] = true
						itemConf.Hidden = true
						if itemConf:IsTrinket() then
							itemPool:RemoveTrinket(itemConf.ID)
						end
					end
					EdithRestored.SaveManager.Save()
				end,
				true
			)

			ImGui.AddCallback(elemName, ImGuiCallback.Render, function()
				local val = true
				for indexItem, disabledItem in pairs(EdithRestored:GetDefaultFileSave(toggles)) do
					if lookupTable[indexItem] == itemConf.ID then
						val = false
						break
					end
				end
				ImGui.UpdateData(elemName, ImGuiData.Value, val)
			end)
		end
	end
	ImGui.SetWindowSize("edithWindowToggles"..t, 600, 10 + i * 90 + (1 - i) * 44)
end

local function UpdateTogglesMenu(show)
    for _, t in ipairs({"Items", "Trinkets"}) do
        if not ShowTogglesButton(t) then
            if ImGui.ElementExists("edithWindowToggles"..t) then
                ImGui.RemoveWindow("edithWindowToggles"..t)
            end
            if ImGui.ElementExists("edithMenuToggles"..t) then
                ImGui.RemoveElement("edithMenuToggles"..t)
            end
            goto continue
        end
        if not ImGui.ElementExists("edithMenuToggles"..t) then
            ImGui.AddElement("EdithRestored", "edithMenuToggles"..t, ImGuiElement.MenuItem, "\u{f05e} "..t.." Toggles")
        end

        if not ImGui.ElementExists("edithWindowToggles"..t) then
            ImGui.CreateWindow("edithWindowToggles"..t, t.." Toggles")
            ImGui.LinkWindowToElement("edithWindowToggles"..t, "edithMenuToggles"..t)
        end
        if show then
            if ImGui.ElementExists("edithMenuToggles"..t.."NoWay") then
                ImGui.RemoveElement("edithMenuToggles"..t.."NoWay")
            end
            ReOrederItems(t)
        else
            RemoveTogglesItems(t)
            if not ImGui.ElementExists("edithMenuToggles"..t.."NoWay") then
                ImGui.AddText(
                    "edithWindowToggles"..t,
                    "Options will be available after loading the game.",
                    true,
                    "edithMenuToggles"..t.."NoWay"
                )
            end
        end
        ::continue::
    end
end

local function UpdateSettingsMenu(show)
	if not ImGui.ElementExists("edithMenuSettings") then
		ImGui.AddElement("EdithRestored", "edithMenuSettings", ImGuiElement.MenuItem, "\u{f013} Settings")
	end

	if not ImGui.ElementExists("edithWindowSettings") then
		ImGui.CreateWindow("edithWindowSettings", "Edith Settings")
		ImGui.LinkWindowToElement("edithWindowSettings", "edithMenuSettings")
		ImGui.SetWindowSize("edithWindowSettings", 800, 350)
	end
	if show then
		if ImGui.ElementExists("edithMenuSettingsNoWay") then
			ImGui.RemoveElement("edithMenuSettingsNoWay")
		end

		if not ImGui.ElementExists("edithPushToSlide") then
			ImGui.AddCheckbox("edithWindowSettings", "edithPushToSlide", "Slide when holding button", function(val)
				EdithRestored:AddDefaultFileSave("AllowHolding", val)
				EdithRestored.SaveManager.Save()
			end, true)
		end

		if not ImGui.ElementExists("edithAllowBombs") then
			ImGui.AddCheckbox("edithWindowSettings", "edithAllowBombs", "Edith can use bombs", function(val)
				EdithRestored:AddDefaultFileSave("OnlyStomps", val)
				EdithRestored.SaveManager.Save()
			end, true)
		end

		if not ImGui.ElementExists("edithTargetColorRGB") then
			
			ImGui.AddInputColor("edithWindowSettings", "edithTargetColorRGB", "\u{f1fc} Edith's Target Color", function(r, g, b)
				local targetColor = EdithRestored:GetDefaultFileSave("TargetColor")
				targetColor.R = math.floor(r * 255)
				targetColor.G = math.floor(g * 255)
				targetColor.B = math.floor(b * 255)
				EdithRestored.SaveManager.Save()
			end, 155 / 255, 0, 0)
		end

		ImGui.AddCallback("edithWindowSettings", ImGuiCallback.Render, function()
			ImGui.UpdateData("edithPushToSlide", ImGuiData.Value, EdithRestored:GetDefaultFileSave("AllowHolding"))
			ImGui.UpdateData("edithAllowBombs", ImGuiData.Value, EdithRestored:GetDefaultFileSave("OnlyStomps"))
			local rgb = EdithRestored:GetDefaultFileSave("TargetColor")
			ImGui.UpdateData("edithTargetColorRGB", ImGuiData.ColorValues, { rgb.R / 255, rgb.G / 255, rgb.B / 255 })
		end)
	else
		ImGui.RemoveCallback("edithWindowSettings", ImGuiCallback.Render)

		if ImGui.ElementExists("edithMenuSettingsNoWay") then
			ImGui.RemoveElement("edithMenuSettingsNoWay")
		end

		if ImGui.ElementExists("edithPushToSlide") then
			ImGui.RemoveElement("edithPushToSlide")
		end

		if ImGui.ElementExists("edithAllowBombs") then
			ImGui.RemoveElement("edithAllowBombs")
		end

		if ImGui.ElementExists("edithTargetColorRGB") then
			ImGui.RemoveElement("edithTargetColorRGB")
		end

		if not ImGui.ElementExists("edithMenuSettingsNoWay") then
			ImGui.AddText(
				"edithWindowSettings",
				"Options will be available after loading the game.",
				true,
				"edithMenuSettingsNoWay"
			)
		end
	end
end

local function RedMoonSilder(bool)
	if bool and ImGui.ElementExists("edithDebugModeTabRedHood") then
		if ImGui.ElementExists("edithDebugModeTabRedHoodText") then
			ImGui.RemoveElement("edithDebugModeTabRedHoodText")
		end
		if not ImGui.ElementExists("edithDebugModeTabRedHoodPhase") then
			ImGui.AddSliderInteger(
				"edithDebugModeTabRedHood",
				"edithDebugModeTabRedHoodPhase",
				"Red Moon phase",
				function(newVal)
					EdithRestored.SetRedMoon(newVal == 5 or EdithRestored:GetDebugValue("AlwaysRedMoon"))
					EdithRestored.SetMoon(
						newVal,
						newVal == 5 or EdithRestored:GetDebugValue("AlwaysRedMoon"),
						EdithRestored:RunSave()["MoonPhase"] > newVal
					)
					EdithRestored:RunSave()["MoonPhase"] = newVal
				end,
				EdithRestored:RunSave()["MoonPhase"],
				1,
				8
			)

			ImGui.AddCallback("edithDebugModeTabRedHoodPhase", ImGuiCallback.Render, function()
				ImGui.UpdateData("edithDebugModeTabRedHoodPhase", ImGuiData.Value, EdithRestored:RunSave()["MoonPhase"])
			end)
		end
		if not ImGui.ElementExists("edithDebugModeTabRedHoodAlwaysShowMoonPhase") then
			ImGui.AddCheckbox(
				"edithDebugModeTabRedHood",
				"edithDebugModeTabRedHoodAlwaysShowMoonPhase",
				"Always show Moon phase",
				function(newVal)
					EdithRestored:SetDebugValue("AlwaysShowMoonPhase", newVal)
					EdithRestored.SetRedMoon(newVal == 5 or EdithRestored:GetDebugValue("AlwaysRedMoon"))
				end,
				EdithRestored:GetDebugValue("AlwaysShowMoonPhase")
			)
			ImGui.AddCallback("edithDebugModeTabRedHoodAlwaysShowMoonPhase", ImGuiCallback.Render, function()
				ImGui.UpdateData(
					"edithDebugModeTabRedHoodAlwaysShowMoonPhase",
					ImGuiData.Value,
					EdithRestored:GetDebugValue("AlwaysShowMoonPhase")
				)
			end)
		end
		if not ImGui.ElementExists("edithDebugModeTabRedHoodAdvance") then
			ImGui.AddCheckbox(
				"edithDebugModeTabRedHood",
				"edithDebugModeTabRedHoodAdvance",
				"Disable Moon phase advancement",
				function(newVal)
					EdithRestored:SetDebugValue("DisableMoonProgression", newVal)
				end,
				EdithRestored:GetDebugValue("DisableMoonProgression")
			)
			ImGui.AddCallback("edithDebugModeTabRedHoodAdvance", ImGuiCallback.Render, function()
				ImGui.UpdateData(
					"edithDebugModeTabRedHoodAdvance",
					ImGuiData.Value,
					EdithRestored:GetDebugValue("DisableMoonProgression")
				)
			end)
		end
		if not ImGui.ElementExists("edithDebugModeTabRedHoodAlwaysRedMoon") then
			ImGui.AddCheckbox(
				"edithDebugModeTabRedHood",
				"edithDebugModeTabRedHoodAlwaysRedMoon",
				"Always Red moon phase",
				function(newVal)
					EdithRestored:SetDebugValue("AlwaysRedMoon", newVal)
					EdithRestored.SetRedMoon(EdithRestored:RunSave()["MoonPhase"] == 5 or newVal)
				end,
				EdithRestored:GetDebugValue("AlwaysRedMoon")
			)
			ImGui.AddCallback("edithDebugModeTabRedHoodAlwaysRedMoon", ImGuiCallback.Render, function()
				ImGui.UpdateData(
					"edithDebugModeTabRedHoodAlwaysRedMoon",
					ImGuiData.Value,
					EdithRestored:GetDebugValue("AlwaysRedMoon")
				)
			end)
		end
	else
		for _, text in ipairs({
			"edithDebugModeTabRedHoodPhase",
			"edithDebugModeTabRedHoodAlwaysShowMoonPhase",
			"edithDebugModeTabRedHoodAdvance",
			"edithDebugModeTabRedHoodAlwaysRedMoon",
		}) do
			if ImGui.ElementExists(text) then
				ImGui.RemoveElement(text)
			end
		end
		if
			not ImGui.ElementExists("edithDebugModeTabRedHoodText") and ImGui.ElementExists("edithDebugModeTabRedHood")
		then
			ImGui.AddText(
				"edithDebugModeTabRedHood",
				"Enter run for options to appear",
				true,
				"edithDebugModeTabRedHoodText"
			)
		end
	end
end

local function UpdateImGuiMenu(IsDataInitialized)
	UpdateSettingsMenu(IsDataInitialized)
	UpdateTogglesMenu(IsDataInitialized)
end

local function UpdateDebugMode()
	if EdithRestored.DebugMode then
		--#region Init ImGui menu
		if not ImGui.ElementExists("edithDebugModeSettings") then
			ImGui.AddElement(
				"EdithRestored",
				"edithDebugModeSettings",
				ImGuiElement.MenuItem,
				"\u{f188} Debug Mode Settings"
			)
		end

		if not ImGui.ElementExists("edithWindowDebugModeSettings") then
			ImGui.CreateWindow("edithWindowDebugModeSettings", "Debug Mode Settings")
			ImGui.LinkWindowToElement("edithWindowDebugModeSettings", "edithDebugModeSettings")
			ImGui.SetWindowSize("edithWindowDebugModeSettings", 800, 350)
		end

		if ImGui.ElementExists("edithDebugModeTabBar") then
			ImGui.RemoveElement("edithDebugModeTabBar")
		end

		ImGui.AddTabBar("edithWindowDebugModeSettings", "edithDebugModeTabBar")

		ImGui.AddTab("edithDebugModeTabBar", "edithDebugModeTabEdith", "Edith")
		ImGui.AddTab("edithDebugModeTabBar", "edithDebugModeTabPeppermintCloud", "Peppermint Cloud")
		ImGui.AddTab("edithDebugModeTabBar", "edithDebugModeTabRedHood", "Red Hood")
		ImGui.AddTab("edithDebugModeTabBar", "edithDebugModeTabMisc", "Miscellaneous")

		--#endregion

		--#region Edith specific
		ImGui.AddSliderInteger("edithDebugModeTabEdith", "edithDebugModeStompRadius", "Stomp radius", function(newVal)
			EdithRestored:SetDebugValue("StompRadius", newVal)
		end, EdithRestored:GetDebugValue("StompRadius"), 30, 100)

		ImGui.AddButton("edithDebugModeTabEdith", "edithDebugModeStompRadiusButtonReset", "Reset", function(newVal)
			EdithRestored:SetDefaultDebugValue("StompRadius")
			ImGui.UpdateData("edithDebugModeStompRadius", ImGuiData.Value, EdithRestored:GetDebugValue("StompRadius"))
		end, false)

		ImGui.AddSliderFloat("edithDebugModeTabEdith", "edithDebugModeJumpHeight", "Jump Height", function(newVal)
			EdithRestored:SetDebugValue("JumpHeight", newVal)
		end, EdithRestored:GetDebugValue("JumpHeight"), 1, 10, "%.2f")

		if ImGui.ElementExists("edithDebugModeJumpHeightButtonReset") then
			ImGui.RemoveElement("edithDebugModeJumpHeightButtonReset")
		end

		ImGui.AddButton("edithDebugModeTabEdith", "edithDebugModeJumpHeightButtonReset", "Reset", function(newVal)
			EdithRestored:SetDefaultDebugValue("JumpHeight")
			ImGui.UpdateData("edithDebugModeJumpHeight", ImGuiData.Value, EdithRestored:GetDebugValue("JumpHeight"))
		end, false)

		ImGui.AddSliderFloat("edithDebugModeTabEdith", "edithDebugModeJumpGravity", "Jump Gravity", function(newVal)
			EdithRestored:SetDebugValue("Gravity", newVal)
		end, EdithRestored:GetDebugValue("Gravity"), 0.1, 5, "%.2f")

		ImGui.AddButton("edithDebugModeTabEdith", "edithDebugModeJumpGravityButtonReset", "Reset", function(newVal)
			EdithRestored:SetDefaultDebugValue("Gravity")
			ImGui.UpdateData("edithDebugModeJumpGravity", ImGuiData.Value, EdithRestored:GetDebugValue("Gravity"))
		end, false)

		ImGui.AddSliderInteger(
			"edithDebugModeTabEdith",
			"edithDebugModeJumpLandingIFrames",
			"Post-landing i-frames",
			function(newVal)
				EdithRestored:SetDebugValue("IFrames", newVal)
			end,
			EdithRestored:GetDebugValue("IFrames"),
			1,
			300
		)

		ImGui.AddButton(
			"edithDebugModeTabEdith",
			"edithDebugModeJumpLandingIFramesButtonReset",
			"Reset",
			function(newVal)
				EdithRestored:SetDefaultDebugValue("IFrames")
				ImGui.UpdateData(
					"edithDebugModeJumpLandingIFrames",
					ImGuiData.Value,
					EdithRestored:GetDebugValue("IFrames")
				)
			end,
			false
		)

		ImGui.AddCheckbox(
			"edithDebugModeTabEdith",
			"edithDebugModeJumpLandingIFramesCheck",
			"Use debug i-frames",
			function(newVal)
				EdithRestored:SetDebugValue("UseIFrames", newVal)
			end,
			EdithRestored:GetDebugValue("UseIFrames")
		)

		ImGui.AddCheckbox(
			"edithDebugModeTabEdith",
			"edithDebugModeInstaJumpCharge",
			"Instant Jump Charge",
			function(newVal)
				EdithRestored:SetDebugValue("InstantJumpCharge", newVal)
			end,
			EdithRestored:GetDebugValue("InstantJumpCharge")
		)

		ImGui.AddCheckbox("edithDebugModeTabEdith", "edithDebugModeIgnoreStomp", "Ignore stomp damage", function(newVal)
			EdithRestored:SetDebugValue("IgnoreStompDamage", newVal)
		end, EdithRestored:GetDebugValue("IgnoreStompDamage"))

		ImGui.UpdateData("edithDebugModeStompRadius", ImGuiData.Value, EdithRestored:GetDebugValue("StompRadius"))
		ImGui.UpdateData(
			"edithDebugModeInstaJumpCharge",
			ImGuiData.Value,
			EdithRestored:GetDebugValue("InstantJumpCharge")
		)

		ImGui.UpdateData("edithDebugModeJumpHeight", ImGuiData.Value, EdithRestored:GetDebugValue("JumpHeight"))
		ImGui.UpdateData("edithDebugModeJumpGravity", ImGuiData.Value, EdithRestored:GetDebugValue("Gravity"))
		ImGui.UpdateData("edithDebugModeIgnoreStomp", ImGuiData.Value, EdithRestored:GetDebugValue("IgnoreStompDamage"))

		--#endregion

		--#region Peppermint specific
		ImGui.AddSliderInteger(
			"edithDebugModeTabPeppermintCloud",
			"edithDebugModePeppermintCharge",
			"Peppermint Max Charge",
			function(newVal)
				EdithRestored:SetDebugValue("PeppermintCharge", newVal)
			end,
			EdithRestored:GetDebugValue("PeppermintCharge"),
			1,
			210
		)

		ImGui.AddButton(
			"edithDebugModeTabPeppermintCloud",
			"edithDebugModePeppermintChargeReset",
			"Reset",
			function(newVal)
				EdithRestored:SetDefaultDebugValue("PeppermintCharge")
				ImGui.UpdateData(
					"edithDebugModePeppermintCharge",
					ImGuiData.Value,
					EdithRestored:GetDebugValue("PeppermintCharge")
				)
			end,
			false
		)

		ImGui.UpdateData(
			"edithDebugModePeppermintCharge",
			ImGuiData.Value,
			EdithRestored:GetDebugValue("PeppermintCharge")
		)

		ImGui.AddSliderInteger(
			"edithDebugModeTabPeppermintCloud",
			"edithDebugModePeppermintCloudSize",
			"Peppermint Cloud Size",
			function(newVal)
				EdithRestored:SetDebugValue("PeppermintCloudSize", newVal)
			end,
			EdithRestored:GetDebugValue("PeppermintCloudSize"),
			1,
			100
		)

		ImGui.AddButton(
			"edithDebugModeTabPeppermintCloud",
			"edithDebugModePeppermintCloudSizeReset",
			"Reset",
			function(newVal)
				EdithRestored:SetDefaultDebugValue("PeppermintCloudSize")
				ImGui.UpdateData(
					"edithDebugModePeppermintCloudSize",
					ImGuiData.Value,
					EdithRestored:GetDebugValue("PeppermintCloudSize")
				)
			end,
			false
		)
		ImGui.UpdateData(
			"edithDebugModePeppermintCloudSize",
			ImGuiData.Value,
			EdithRestored:GetDebugValue("PeppermintCloudSize")
		)

		ImGui.AddSliderInteger(
			"edithDebugModeTabPeppermintCloud",
			"edithDebugModePeppermintCloudPosOffsetX",
			"Peppermint Cloud Position X Offset",
			function(newVal)
				EdithRestored:SetDebugValue("PeppermintCloudPosOffsetX", newVal)
			end,
			EdithRestored:GetDebugValue("PeppermintCloudPosOffsetX"),
			-100,
			100
		)
		ImGui.UpdateData(
			"edithDebugModePeppermintCloudPosOffsetX",
			ImGuiData.Value,
			EdithRestored:GetDebugValue("PeppermintCloudPosOffsetX")
		)

		ImGui.AddSliderInteger(
			"edithDebugModeTabPeppermintCloud",
			"edithDebugModePeppermintCloudPosOffsetY",
			"Peppermint Cloud Position Y Offset",
			function(newVal)
				EdithRestored:SetDebugValue("PeppermintCloudPosOffsetY", newVal)
			end,
			EdithRestored:GetDebugValue("PeppermintCloudPosOffsetY"),
			-100,
			100
		)

		ImGui.AddButton(
			"edithDebugModeTabPeppermintCloud",
			"edithDebugModePeppermintCloudPosOffsetReset",
			"Reset",
			function(newVal)
				EdithRestored:SetDefaultDebugValue("PeppermintCloudPosOffsetX")
				EdithRestored:SetDefaultDebugValue("PeppermintCloudPosOffsetY")
				ImGui.UpdateData(
					"edithDebugModePeppermintCloudPosOffsetX",
					ImGuiData.Value,
					EdithRestored:GetDebugValue("PeppermintCloudPosOffsetX")
				)
				ImGui.UpdateData(
					"edithDebugModePeppermintCloudPosOffsetY",
					ImGuiData.Value,
					EdithRestored:GetDebugValue("PeppermintCloudPosOffsetY")
				)
			end,
			false
		)
		ImGui.UpdateData(
			"edithDebugModePeppermintCloudPosOffsetY",
			ImGuiData.Value,
			EdithRestored:GetDebugValue("PeppermintCloudPosOffsetY")
		)

		ImGui.AddSliderFloat(
			"edithDebugModeTabPeppermintCloud",
			"edithDebugModePeppermintCloudSizeXMult",
			"Peppermint Cloud Position X Offset",
			function(newVal)
				EdithRestored:SetDebugValue("PeppermintCloudSizeXMult", newVal)
			end,
			EdithRestored:GetDebugValue("PeppermintCloudSizeXMult"),
			0.1,
			5
		)
		ImGui.UpdateData(
			"edithDebugModePeppermintCloudSizeXMult",
			ImGuiData.Value,
			EdithRestored:GetDebugValue("PeppermintCloudSizeXMult")
		)

		ImGui.AddSliderFloat(
			"edithDebugModeTabPeppermintCloud",
			"edithDebugModePeppermintCloudSizeYMult",
			"Peppermint Cloud Position Y Offset",
			function(newVal)
				EdithRestored:SetDebugValue("PeppermintCloudSizeYMult", newVal)
			end,
			EdithRestored:GetDebugValue("PeppermintCloudSizeYMult"),
			0.1,
			5
		)

		ImGui.AddButton(
			"edithDebugModeTabPeppermintCloud",
			"edithDebugModePeppermintCloudSizeMultReset",
			"Reset",
			function(newVal)
				EdithRestored:SetDefaultDebugValue("PeppermintCloudSizeXMult")
				EdithRestored:SetDefaultDebugValue("PeppermintCloudPosOffsetY")
				ImGui.UpdateData(
					"edithDebugModePeppermintCloudSizeXMult",
					ImGuiData.Value,
					EdithRestored:GetDebugValue("PeppermintCloudSizeXMult")
				)
				ImGui.UpdateData(
					"edithDebugModePeppermintCloudSizeYMult",
					ImGuiData.Value,
					EdithRestored:GetDebugValue("PeppermintCloudSizeYMult")
				)
			end,
			false
		)
		ImGui.UpdateData(
			"edithDebugModePeppermintCloudSizeYMult",
			ImGuiData.Value,
			EdithRestored:GetDebugValue("PeppermintCloudSizeYMult")
		)

		--#endregion

		--#region Misc specific
		ImGui.AddSliderInteger(
			"edithDebugModeTabMisc",
			"edithDebugModeBlastingBootsCd",
			"Blasting Boots cooldown",
			function(newVal)
				EdithRestored:SetDebugValue("BlastingBootsCd", newVal)
			end,
			EdithRestored:GetDebugValue("BlastingBootsCd"),
			30,
			150
		)

		ImGui.AddButton("edithDebugModeTabMisc", "edithDebugModeBlastingBootsCdReset", "Reset", function(newVal)
			EdithRestored:SetDefaultDebugValue("BlastingBootsCd")
			ImGui.UpdateData(
				"edithDebugModeBlastingBootsCd",
				ImGuiData.Value,
				EdithRestored:GetDebugValue("BlastingBootsCd")
			)
		end, false)
		ImGui.UpdateData(
			"edithDebugModeBlastingBootsCd",
			ImGuiData.Value,
			EdithRestored:GetDebugValue("BlastingBootsCd")
		)

		ImGui.AddCheckbox(
			"edithDebugModeTabMisc",
			"edithDebugModeBlastingBootsDisable",
			"Disable Blasting Boots cooldown",
			function(newVal)
				EdithRestored:SetDebugValue("BlastingBootsDisable", newVal)
			end,
			EdithRestored:GetDebugValue("BlastingBootsDisable")
		)
		ImGui.UpdateData(
			"edithDebugModeBlastingBootsDisable",
			ImGuiData.Value,
			EdithRestored:GetDebugValue("BlastingBootsDisable")
		)
		--#endregion

		--#region Red Hood specific

		RedMoonSilder(EdithRestored.SaveManager.IsLoaded())
		--#endregion
		ImGui.SetVisible("edithWindowDebugModeSettings", true)
	else
		if ImGui.ElementExists("edithDebugModeSettings") then
			ImGui.RemoveElement("edithDebugModeSettings")
		end
		if ImGui.ElementExists("edithWindowDebugModeSettings") then
			ImGui.RemoveWindow("edithWindowDebugModeSettings")
		end
	end
end

local function InitImGuiMenu()
	if not ImGui.ElementExists("RestoredMods") then
		ImGui.CreateMenu("RestoredMods", "Restored Mods")
	end

	if not ImGui.ElementExists("EdithRestored") then
		ImGui.AddElement("RestoredMods", "EdithRestored", ImGuiElement.Menu, "Edith")
	end

	UpdateImGuiMenu()
	--UpdateTogglesMenu()

	if not ImGui.ElementExists("edithMenuUnlocks") then
		ImGui.AddElement("EdithRestored", "edithMenuUnlocks", ImGuiElement.MenuItem, "\u{f09c} Unlocks")
	end

	if not ImGui.ElementExists("edithWindowUnlocks") then
		ImGui.CreateWindow("edithWindowUnlocks", "Edith Unlocks")
		ImGui.LinkWindowToElement("edithWindowUnlocks", "edithMenuUnlocks")
	end

	local marksA = EdithRestored.Enums.Achievements.Unlocks.ASide
	--local marksB = EdithRestored.Enums.Achievements.Unlocks.BSide

	local challenges = EdithRestored.Enums.Achievements.Unlocks.Challenges

	local function LockAchievementA(id)
		if type(id) == "number" then
			Isaac.ExecuteCommand("lockachievement " .. id)
		end
	end

	local function UnLockAchievementA(id)
		if type(id) == "number" then
			if not pgd:Unlocked(id) then
				Isaac.ExecuteCommand("achievement " .. id)
			end
		end
	end

	local function SetHelpMarker(tab, func, ach, elem)
		for _, item in pairs(tab) do
			local conf = func(itemConfig, item)
			if conf then
				if conf.AchievementID > 0 and ach and ach == conf.AchievementID then
					ImGui.SetHelpmarker(elem, "Unlocks " .. RemoveZeroWidthSpace(conf.Name))
					break
				end
			end
		end
	end

	if ImGui.ElementExists("edithMarks") then
		ImGui.RemoveElement("edithMarks")
	end

	ImGui.AddTabBar("edithWindowUnlocks", "edithMarks")
	--#region Edith unlocks
	ImGui.AddTab("edithMarks", "edithUnlocksA", "Edith")
	--ImGui.AddTab("edithMarks", "edithUnlocksB", "Tainted Edith")

	if ImGui.ElementExists("edithMarksBTainted") then
		ImGui.RemoveElement("edithMarksBTainted")
	end
	--[[ImGui.AddCombobox("edithUnlocksB", "edithMarksBTainted", "Tainted Edith", function(index, val)
		if index == 1 then
			UnLockAchievementA(EdithRestored.Enums.Achievements.Characters.TAINTED)
		else
			LockAchievementA(EdithRestored.Enums.Achievements.Characters.TAINTED)
		end
		UpdateTogglesMenu()
	end, { "Locked", "Unlocked" }, 0, true)
	ImGui.AddCallback("edithMarksBTainted", ImGuiCallback.Render, function()
		ImGui.UpdateData(
			"edithMarksBTainted",
			ImGuiData.Value,
			pgd:Unlocked(EdithRestored.Enums.Achievements.Characters.TAINTED) and 1 or 0
		)
	end)]]

	for tab, prefix in pairs({ ["edithUnlocksA"] = "edithMarksA", --[["edithUnlocksB"] = "edithMarksB"]] }) do
		local pType = EdithRestored.Enums.PlayerType.EDITH--prefix == "edithMarksA" and EdithRestored.Enums.PlayerType.EDITH
			--or EdithRestored.Enums.PlayerType.EDITH_B
		local achievements = marksA--prefix == "edithMarksA" and marksA or marksB
		for ach, data in pairs(achievements) do
			if data.Name ~= nil and data.Difficulty ~= nil and ach > 0 then
				if ImGui.ElementExists(prefix .. data.Name) then
					ImGui.RemoveElement(prefix .. data.Name)
				end
				ImGui.AddCombobox(tab, prefix .. data.Name, data.Name, function(index, val)
					if index == 1 then
						for _, mark in pairs(data.Marks) do
							local diff = data.Difficulty ~= nil and data.Difficulty or 2
							Isaac.SetCompletionMark(pType, mark, math.max(diff, Isaac.GetCompletionMark(pType, mark)))
						end
						UnLockAchievementA(ach)
					else
						for _, mark in pairs(data.Marks) do
							Isaac.SetCompletionMark(pType, mark, 0)
						end
						LockAchievementA(ach)
					end
					if data.Function then
						data.Function(index)
					end
					UpdateTogglesMenu(EdithRestored.SaveManager.Utility.IsDataInitialized() and Isaac.IsInGame())
				end, { "Locked", "Unlocked" }, 0, true)
				ImGui.AddCallback(prefix .. data.Name, ImGuiCallback.Render, function()
					ImGui.UpdateData(prefix .. data.Name, ImGuiData.Value, pgd:Unlocked(ach) and 1 or 0)
				end)

				if data.Type == "Item" then
					SetHelpMarker(EdithRestored.Enums.CollectibleType, itemConfig.GetCollectible, ach, prefix .. data.Name)
				elseif data.Type == "Trinket" then
					SetHelpMarker(EdithRestored.Enums.TrinketType, itemConfig.GetTrinket, ach, prefix .. data.Name)
				elseif data.Type == "Card" then
					SetHelpMarker(EdithRestored.Enums.Pickups.Cards, itemConfig.GetCard, ach, prefix .. data.Name)
				end
				if data.ExtraData then
					data.ExtraData(prefix .. data.Name)
				end
			end
		end
	end

	--ImGui.SetTooltip()

	ImGui.AddCombobox("edithUnlocksA", "edithMarksAAll", "All Marks", function(index, val)
		if index < 1 then
			Isaac.ExecuteCommand("lockachievement " .. EdithRestored.Enums.Achievements.CompletionMarks.SOUL_EDITH)
		elseif not pgd:Unlocked(EdithRestored.Enums.Achievements.CompletionMarks.SOUL_EDITH) then
			for key, val in pairs(marksA) do
				if not pgd:Unlocked(key) then
					Isaac.ExecuteCommand("achievement " .. key)
				end
				for _, mark in pairs(val.Marks) do
					Isaac.SetCompletionMark(EdithRestored.Enums.PlayerType.EDITH, mark, 2)
				end
			end
			Isaac.ExecuteCommand("achievement " .. EdithRestored.Enums.Achievements.CompletionMarks.SOUL_EDITH)
		end
		UpdateTogglesMenu(EdithRestored.SaveManager.Utility.IsDataInitialized() and Isaac.IsInGame())
	end, { "Locked", "Unlocked" }, 0, true)

	ImGui.AddCallback("edithMarksAAll", ImGuiCallback.Render, function()
		local unlocked = pgd:Unlocked(EdithRestored.Enums.Achievements.CompletionMarks.SOUL_EDITH)
		ImGui.UpdateData("edithMarksAAll", ImGuiData.Value, unlocked and 1 or 0)
	end)

	local cardConf = itemConfig:GetCard(EdithRestored.Enums.Pickups.Cards.CARD_SOUL_EDITH)
	if cardConf then
		ImGui.SetHelpmarker("edithMarksAAll", "Unlocks " .. RemoveZeroWidthSpace(cardConf.Name))
	end
	--#endregion

	--#region Challenges unlocks
	ImGui.AddTab("edithMarks", "edithChallenges", "Challenges")

	for key, val in pairs(challenges) do
		if ImGui.ElementExists("edithChallenge" .. val.Name) then
			ImGui.RemoveElement("edithChallenge" .. val.Name)
		end

		ImGui.AddCombobox("edithChallenges", "edithChallenge" .. val.Name, val.Name, function(index, value)
			if index == 0 then
				Isaac.ExecuteCommand("lockachievement " .. key)
			end
			if index > 0 then
				if not pgd:Unlocked(key) then
					Isaac.ExecuteCommand("achievement " .. key)
				end
			end
			if val.Function then
				val.Function(index)
			end
			UpdateTogglesMenu(EdithRestored.SaveManager.Utility.IsDataInitialized() and Isaac.IsInGame())
		end, { "Locked", "Unlocked" }, 0, true)

		ImGui.AddCallback("edithChallenge" .. val.Name, ImGuiCallback.Render, function()
			ImGui.UpdateData("edithChallenge" .. val.Name, ImGuiData.Value, pgd:Unlocked(key) and 1 or 0)
		end)

		if val.Type == "Item" then
			SetHelpMarker(EdithRestored.Enums.CollectibleType, itemConfig.GetCollectible, key, "edithChallenge" .. val.Name)
		elseif val.Type == "Trinket" then
			SetHelpMarker(EdithRestored.Enums.TrinketType, itemConfig.GetTrinket, key, "edithChallenge" .. val.Name)
		elseif val.Type == "Card" then
			SetHelpMarker(EdithRestored.Enums.Pickups.Cards, itemConfig.GetCard, key, "edithChallenge" .. val.Name)
		end
		if val.ExtraData then
			val.ExtraData("edithChallenge" .. val.Name)
		end
	end
	--#endregion

	ImGui.SetWindowSize("edithWindowUnlocks", 800, 650)
end

EdithRestored:AddCallback(ModCallbacks.MC_POST_COMPLETION_MARK_GET, function()
	UpdateTogglesMenu(EdithRestored.SaveManager.Utility.IsDataInitialized())
end, EdithRestored.Enums.PlayerType.EDITH)

---@param cmd string
EdithRestored:AddCallback(ModCallbacks.MC_EXECUTE_CMD, function(_, cmd, args)
	if string.lower(cmd):match("achievement") == "achievement" then
		UpdateTogglesMenu(EdithRestored.SaveManager.Utility.IsDataInitialized() and Isaac.IsInGame())
	end
end, EdithRestored.Enums.PlayerType.EDITH)

InitImGuiMenu()
UpdateImGuiMenu()
UpdateDebugMode()

local InGame = false

local function UpdateImGuiOnRender()
	if not Isaac.IsInGame() and InGame then
		UpdateImGuiMenu(false)
		InGame = false
	elseif Isaac.IsInGame() and not InGame then
		UpdateImGuiMenu(true)
		InGame = true
	end
end
EdithRestored:AddPriorityCallback(ModCallbacks.MC_POST_RENDER, CallbackPriority.LATE, UpdateImGuiOnRender)
EdithRestored:AddPriorityCallback(ModCallbacks.MC_MAIN_MENU_RENDER, CallbackPriority.LATE, UpdateImGuiOnRender)

---@param completion CompletionType
EdithRestored:AddCallback(ModCallbacks.MC_POST_COMPLETION_EVENT, function(_, completion)
	UpdateTogglesMenu(EdithRestored.SaveManager.Utility.IsDataInitialized() and Isaac.IsInGame())
end)

EdithRestored:AddPriorityCallback(ModCallbacks.MC_POST_GAME_STARTED, 1000, function()
	RedMoonSilder(EdithRestored.SaveManager.IsLoaded())
end)

EdithRestored:AddPriorityCallback(ModCallbacks.MC_PRE_GAME_EXIT, -1000, function()
	RedMoonSilder(false)
end)

EdithRestored:AddCallback(ModCallbacks.MC_EXECUTE_CMD, function(_, cmd, args)
	if cmd == "edithdebug" then
		if args == "enable" then
			EdithRestored.DebugMode = true
			EdithRestored:Log("Edith Debug Mode is enabled.", true)
			UpdateDebugMode()
		elseif args == "disable" then
			EdithRestored.DebugMode = false
			EdithRestored:Log("Edith Debug Mode is disabled.", true)
			UpdateDebugMode()
		end
	end
end)

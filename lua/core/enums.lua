local Enums = {}
local pgd = EdithRestored.PGD

Enums.MouseClick = { LEFT = 0, RIGHT = 1, WHEEL = 2, BACK = 3, FORWARD = 4 }

Enums.Entities = {
	--[[FALLING_CHISEL = {
		Type = Isaac.GetEntityTypeByName("The Chisel"),
		Variant = Isaac.GetEntityVariantByName("The Chisel"),
		SubType = 0,
	},]]
	SALT_STATUE = {
		Type = Isaac.GetEntityTypeByName("Salt Statue"),
		Variant = Isaac.GetEntityVariantByName("Salt Statue"),
		SubType = 0,
	},
	SALT_STATUE_MINI = {
		Type = Isaac.GetEntityTypeByName("Mini Salt Statue"),
		Variant = Isaac.GetEntityVariantByName("Mini Salt Statue"),
		SubType = 0,
	},
	EDITH_TARGET = {
		Type = Isaac.GetEntityTypeByName("Restored Edith Target"),
		Variant = Isaac.GetEntityVariantByName("Restored Edith Target"),
		SubType = 0,
	},
	SALT_CREEP = {
		Type = Isaac.GetEntityTypeByName("Salt Creep"),
		Variant = Isaac.GetEntityVariantByName("Salt Creep"),
		SubType = Isaac.GetEntitySubTypeByName("Salt Creep"),
	},
	PEPPER_CREEP = {
		Type = Isaac.GetEntityTypeByName("Pepper Creep"),
		Variant = Isaac.GetEntityVariantByName("Pepper Creep"),
		SubType = Isaac.GetEntitySubTypeByName("Pepper Creep"),
	},
	PEPPERMINT = {
		Type = Isaac.GetEntityTypeByName("Peppermint Cloud"),
		Variant = Isaac.GetEntityVariantByName("Peppermint Cloud"),
		SubType = 0,
	},
	CUSTOM_DUST_CLOUD = {
		Type = Isaac.GetEntityTypeByName("Custom Dust Cloud"),
		Variant = Isaac.GetEntityVariantByName("Custom Dust Cloud"),
	},
	WEREWOLF_SWIPE = {
		Type = Isaac.GetEntityTypeByName("Werewolf Swipe"),
		Variant = Isaac.GetEntityVariantByName("Werewolf Swipe"),
		SubType = 0,
	},
	SODOM_FIRE = {
		Type = Isaac.GetEntityTypeByName("Sodom Fire"),
		Variant = Isaac.GetEntityVariantByName("Sodom Fire"),
		SubType = 0,
	},
}

Enums.Familiars = {
	SALTY_BABY = {
		Type = Isaac.GetEntityTypeByName("​Salty Baby"),
		Variant = Isaac.GetEntityVariantByName("​Salty Baby"),
		SubType = 0,
	},
	SALT_PAWNS = {
		Type = Isaac.GetEntityTypeByName("Salt Pawns"),
		Variant = Isaac.GetEntityVariantByName("Salt Pawns"),
		SubType = 0,
	},
}

--[[Enums.Slots = {
	ELECTRIFIER = {
		Type = Isaac.GetEntityTypeByName("Electrifier Machine"),
		Variant = Isaac.GetEntityVariantByName("Electrifier Machine"),
		SubType = Isaac.GetEntitySubTypeByName("Electrifier Machine"),
	},
}]]

Enums.PlayerType = {
	EDITH = Isaac.GetPlayerTypeByName("Redith", false),
	EDITH_B = Isaac.GetPlayerTypeByName("Redith", true),
}

Enums.CollectibleType = {
	COLLECTIBLE_PEPPERMINT = Isaac.GetItemIdByName("​Peppermint"),
	COLLECTIBLE_LITHIUM = Isaac.GetItemIdByName("Lithium Salts"),
	COLLECTIBLE_SODOM = Isaac.GetItemIdByName("​Sodom"),
	COLLECTIBLE_BLASTING_BOOTS = Isaac.GetItemIdByName("Blasting Boots"),
	COLLECTIBLE_THUNDER_BOMBS = Isaac.GetItemIdByName("​Thunder Bombs"),
	COLLECTIBLE_SALTY_BABY = Isaac.GetItemIdByName("​Salty Baby"),
	COLLECTIBLE_SALT_PAWNS = Isaac.GetItemIdByName("Salt Pawns"),
	COLLECTIBLE_SALT_SHAKER = Isaac.GetItemIdByName("​Salt Shaker"),
	COLLECTIBLE_GORGON_MASK = Isaac.GetItemIdByName("Gorgon Mask"),
	COLLECTIBLE_RED_HOOD = Isaac.GetItemIdByName("​Red Hood"),
	COLLECTIBLE_SHRAPNEL_BOMBS = Isaac.GetItemIdByName("Shrapnel Bombs"),
	--COLLECTIBLE_THE_CHISEL = Isaac.GetItemIdByName("The Chisel"),
}

Enums.TrinketType = {
	TRINKET_PEPPER_GRINDER = Isaac.GetTrinketIdByName("Pepper Grinder"),
	TRINKET_SALT_ROCK = Isaac.GetTrinketIdByName("Salt Rock"),
	TRINKET_SMELLING_SALTS = Isaac.GetTrinketIdByName("Smelling Salts"),
	TRINKET_CHUNK_OF_AMBER = Isaac.GetTrinketIdByName("Chunk of Amber"),
}

Enums.NullItems = {
	GORGON_MASK = Isaac.GetNullItemIdByName("Gorgon Mask Effect"),
	RED_HOOD = Isaac.GetNullItemIdByName("Red Hood Effect"),
	RED_HOOD_WEREWOLF = Isaac.GetNullItemIdByName("Red Hood Werewolf"),
	LITHIUM_POSITIVE = Isaac.GetNullItemIdByName("Lithium Positive Effect"),
	LITHIUM_NEGATIVE = Isaac.GetNullItemIdByName("Lithium Negative Effect"),
	LITHIUM_FALSEPHD = Isaac.GetNullItemIdByName("Lithium False PHD Effect"),
}

Enums.Pickups = {
	Cards = {
		--CARD_PRUDENCE = Isaac.GetCardIdByName("Prudence"),
		--CARD_REVERSE_PRUDENCE = Isaac.GetCardIdByName("Prudence?"),
		CARD_SOUL_EDITH = Isaac.GetCardIdByName("Soul of Edith"),
	},
	Pills = {
		PILL_LITHIUM = Isaac.GetEntitySubTypeByName("Lithium Pill"),
		PILL_HORSE_LITHIUM = Isaac.GetEntitySubTypeByName("Horse Lithium Pill"),
	},
	PillEffects = {
		PILLEFFECT_LITHIUM = Isaac.GetPillEffectByName("Lithium"),
	},
}

Enums.SFX = {
	Cards = {
		--CARD_PRUDENCE = Isaac.GetSoundIdByName("Prudence"),
		--CARD_REVERSE_PRUDENCE = Isaac.GetSoundIdByName("Reverse Prudence"),
		CARD_SOUL_EDITH = Isaac.GetSoundIdByName("Soul Of Edith"),
	},
	SaltShaker = {
		SHAKE = Isaac.GetSoundIdByName("Salt Shaker Use"),
	},
	Edith = {
		ROCK_SLIDE = Isaac.GetSoundIdByName("RockSlide"),
		WATER_STOMP = Isaac.GetSoundIdByName("stompOnWater"),
	},
	PEPPERMINT_BREATH = Isaac.GetSoundIdByName("Peppermint Breath"),
}

Enums.GFX = {
	Cards = {
		--CARD_PRUDENCE = "Prudence.png",
		--CARD_REVERSE_PRUDENCE = "PrudenceReverse.png",
		CARD_SOUL_EDITH = "SoulOfEdith.png",
	},
}

-- Costumes
Enums.Costumes = {
	EDITH_HOOD = Isaac.GetCostumeIdByPath("gfx/characters/Character_001_Redith_Hood.anm2"),
	--EDITH_B_HAIR = Isaac.GetCostumeIdByPath("gfx/characters/Character_001_Edith_b_Hood.anm2"),
}

Enums.PlayerSprites = {
	EDITH = "gfx/Redith.anm2",
	EDITH_B = "gfx/Redith_b.anm2",
}

Enums.Callbacks = {
	ON_EDITH_STOMP_EXPLOSION = "ON_EDITH_STOMP_EXPLOSION",
	DO_STOMP_EXPLOSION = "DO_STOMP_EXPLOSION",
	ON_EDITH_STOMP_LANDING_IFRAMES = "ON_EDITH_STOMP_LANDING_IFRAMES",
	ON_EDITH_JUMPING = "ON_EDITH_JUMPING",
	ON_EDITH_STOMP = "ON_EDITH_STOMP",
	ON_EDITH_MODIFY_STOMP = "ON_EDITH_MODIFY_STOMP",
}

Enums.BombVariant = {
	BOMB_SHRAPNEL = Isaac.GetEntityVariantByName("Shrapnel Bomb"),
}

Enums.RockVariant = {
	ROCK_SALT = 683,
}

BombFlagsAPI.AddNewCustomBombFlag("THUNDER_BOMB", Enums.CollectibleType.COLLECTIBLE_THUNDER_BOMBS)
BombFlagsAPI.AddNewCustomBombFlag("SHRAPNEL_BOMB", Enums.CollectibleType.COLLECTIBLE_SHRAPNEL_BOMBS)

Enums.Challenges = {
	ROCKET_LACES = Isaac.GetChallengeIdByName("Rocket Laces"),
}

Enums.Achievements = {}
Enums.Achievements.Characters = {
	EDITH = Isaac.GetAchievementIdByName("Edith"),
	TAINTED = Isaac.GetAchievementIdByName("Tainted Edith (Restored Edith)"),
}
Enums.Achievements.CompletionMarks = {
	-- A-side Unlocks
	BLASTING_BOOTS = Isaac.GetAchievementIdByName("Blasting Boots"),
	SALTY_BABY = Isaac.GetAchievementIdByName("​Salty Baby"),
	SALT_SHAKER = Isaac.GetAchievementIdByName("​Salt Shaker"),
	CHUNK_OF_AMBER = Isaac.GetAchievementIdByName("Chunk of Amber"),
	THUNDER_BOMBS = Isaac.GetAchievementIdByName("​Thunder Bombs"),
	SMELLING_SALTS = Isaac.GetAchievementIdByName("Smelling Salts"),
	SALT_PAWNS = Isaac.GetAchievementIdByName("Salt Pawns"),
	GORGON_MASK = Isaac.GetAchievementIdByName("Gorgon Mask"),
	RED_HOOD = Isaac.GetAchievementIdByName("​Red Hood"),
	LITHIUM = Isaac.GetAchievementIdByName("Lithium Salts"),
	SHRAPNEL_BOMBS = Isaac.GetAchievementIdByName("Shrapnel Bombs"),
	SODOM = Isaac.GetAchievementIdByName("​Sodom"),
	SALT_ROCK = Isaac.GetAchievementIdByName("Salt Rock"),
	--PRUDENCE = Isaac.GetAchievementIdByName("Prudence"),
	-- B-side Unlocks
	SOUL_EDITH = Isaac.GetAchievementIdByName("Soul of Edith"),
	--REV_PRUDENCE = Isaac.GetAchievementIdByName("Reverse Prudence"),
	--ELECTRIFIER = Isaac.GetAchievementIdByName("Electrifier"),
	--PEPPER_GRINDER = Isaac.GetAchievementIdByName("Pepper Grinder"),
}
Enums.Achievements.Misc = {
	ROCKET_LACES = Isaac.GetAchievementIdByName("Rocket Laces"),
}
-- Challenges
Enums.Achievements.Challenges = {
	PEPPERMINT = Isaac.GetAchievementIdByName("​Peppermint"),
}

Enums.Achievements.Unlocks = {
	ASide = {
		[Enums.Achievements.CompletionMarks.SALTY_BABY] = {
			Marks = { CompletionType.MOMS_HEART },
			Name = "Mom's Heart",
			Difficulty = 1,
			Type = "Item",
			Condition = function(mark)
				return not pgd:Unlocked(Enums.Achievements.CompletionMarks.SALTY_BABY)
					and Isaac.GetCompletionMark(Enums.PlayerType.EDITH, CompletionType.MOMS_HEART) > 0
			end,
		},
		[Enums.Achievements.CompletionMarks.SALT_SHAKER] = {
			Marks = { CompletionType.ISAAC },
			Name = "Isaac",
			Difficulty = 1,
			Type = "Item",
			Condition = function(mark)
				return not pgd:Unlocked(Enums.Achievements.CompletionMarks.SALT_SHAKER)
					and Isaac.GetCompletionMark(Enums.PlayerType.EDITH, CompletionType.ISAAC) > 0
			end,
		},
		[Enums.Achievements.CompletionMarks.CHUNK_OF_AMBER] = {
			Marks = { CompletionType.SATAN },
			Name = "Satan",
			Difficulty = 1,
			Type = "Trinket",
			Condition = function(mark)
				return not pgd:Unlocked(Enums.Achievements.CompletionMarks.CHUNK_OF_AMBER)
					and Isaac.GetCompletionMark(Enums.PlayerType.EDITH, CompletionType.SATAN) > 0
			end,
		},
		[Enums.Achievements.CompletionMarks.RED_HOOD] = {
			Marks = { CompletionType.BOSS_RUSH },
			Name = "Boss Rush",
			Difficulty = 1,
			Type = "Item",
			Condition = function(mark)
				return not pgd:Unlocked(Enums.Achievements.CompletionMarks.RED_HOOD)
					and Isaac.GetCompletionMark(Enums.PlayerType.EDITH, CompletionType.BOSS_RUSH) > 0
			end,
		},
		[Enums.Achievements.CompletionMarks.THUNDER_BOMBS] = {
			Marks = { CompletionType.BLUE_BABY },
			Name = "Blue Baby",
			Difficulty = 1,
			Type = "Item",
			Condition = function(mark)
				return not pgd:Unlocked(Enums.Achievements.CompletionMarks.THUNDER_BOMBS)
					and Isaac.GetCompletionMark(Enums.PlayerType.EDITH, CompletionType.BLUE_BABY) > 0
			end,
		},
		[Enums.Achievements.CompletionMarks.SMELLING_SALTS] = {
			Marks = { CompletionType.LAMB },
			Name = "Lamb",
			Difficulty = 1,
			Type = "Trinket",
			Condition = function(mark)
				return not pgd:Unlocked(Enums.Achievements.CompletionMarks.SMELLING_SALTS)
					and Isaac.GetCompletionMark(Enums.PlayerType.EDITH, CompletionType.LAMB) > 0
			end,
		},
		[Enums.Achievements.CompletionMarks.SALT_ROCK] = {
			Marks = { CompletionType.MEGA_SATAN },
			Name = "Mega Satan",
			Difficulty = 1,
			Type = "Trinket",
			Condition = function(mark)
				return not pgd:Unlocked(Enums.Achievements.CompletionMarks.SALT_ROCK)
					and Isaac.GetCompletionMark(Enums.PlayerType.EDITH, CompletionType.MEGA_SATAN) > 0
			end,
		},
		[Enums.Achievements.CompletionMarks.BLASTING_BOOTS] = {
			Marks = { CompletionType.HUSH },
			Name = "Hush",
			Difficulty = 1,
			Type = "Item",
			Condition = function(mark)
				return not pgd:Unlocked(Enums.Achievements.CompletionMarks.BLASTING_BOOTS)
					and Isaac.GetCompletionMark(Enums.PlayerType.EDITH, CompletionType.HUSH) > 0
			end,
			Function = function(mark)
				if mark > 0 then
					if not pgd:Unlocked(Enums.Achievements.Misc.ROCKET_LACES) then
						Isaac.ExecuteCommand("achievement " .. Enums.Achievements.Misc.ROCKET_LACES)
					end
				else
					Isaac.ExecuteCommand("lockachievement " .. Enums.Achievements.Misc.ROCKET_LACES)
				end
			end,
		},
		[Enums.Achievements.CompletionMarks.SALT_PAWNS] = {
			Marks = { CompletionType.ULTRA_GREED },
			Name = "Ultra Greed",
			Difficulty = 1,
			Type = "Item",
			Condition = function(mark)
				return not pgd:Unlocked(Enums.Achievements.CompletionMarks.SALT_PAWNS)
					and Isaac.GetCompletionMark(Enums.PlayerType.EDITH, CompletionType.ULTRA_GREED) > 0
			end,
			Function = function(mark)
				if mark == 2 then
					if not pgd:Unlocked(Enums.Achievements.CompletionMarks.GORGON_MASK) then
						Isaac.ExecuteCommand("achievement " .. Enums.Achievements.CompletionMarks.GORGON_MASK)
					end
				else
					Isaac.ExecuteCommand("lockachievement " .. Enums.Achievements.CompletionMarks.GORGON_MASK)
				end
				Isaac.SetCompletionMark(EdithRestored.Enums.PlayerType.EDITH, CompletionType.ULTRA_GREEDIER, mark)
			end,
		},
		[Enums.Achievements.CompletionMarks.GORGON_MASK] = {
			Marks = { CompletionType.ULTRA_GREEDIER },
			Name = "Ultra Greedier",
			Difficulty = 2,
			Type = "Item",
			Condition = function(mark)
				return not pgd:Unlocked(Enums.Achievements.CompletionMarks.GORGON_MASK)
					and Isaac.GetCompletionMark(Enums.PlayerType.EDITH, CompletionType.ULTRA_GREEDIER) > 1
			end,
			Function = function(mark)
				if mark == 2 then
					if not pgd:Unlocked(Enums.Achievements.CompletionMarks.GORGON_MASK) then
						Isaac.ExecuteCommand("achievement " .. Enums.Achievements.CompletionMarks.GORGON_MASK)
					end
					Isaac.SetCompletionMark(EdithRestored.Enums.PlayerType.EDITH, CompletionType.ULTRA_GREED, 2)
				else
					Isaac.ExecuteCommand("lockachievement " .. Enums.Achievements.CompletionMarks.GORGON_MASK)
					Isaac.SetCompletionMark(EdithRestored.Enums.PlayerType.EDITH, CompletionType.ULTRA_GREED, 1)
				end
			end,
		},
		[Enums.Achievements.CompletionMarks.LITHIUM] = {
			Marks = { CompletionType.DELIRIUM },
			Name = "Delirium",
			Difficulty = 1,
			Type = "Item",
			Condition = function(mark)
				return not pgd:Unlocked(Enums.Achievements.CompletionMarks.LITHIUM)
					and Isaac.GetCompletionMark(Enums.PlayerType.EDITH, CompletionType.DELIRIUM) > 0
			end,
		},
		[Enums.Achievements.CompletionMarks.SHRAPNEL_BOMBS] = {
			Marks = { CompletionType.MOTHER },
			Name = "Mother",
			Difficulty = 1,
			Type = "Item",
			Condition = function(mark)
				return not pgd:Unlocked(Enums.Achievements.CompletionMarks.SHRAPNEL_BOMBS)
					and Isaac.GetCompletionMark(Enums.PlayerType.EDITH, CompletionType.MOTHER) > 0
			end,
		},
		[Enums.Achievements.CompletionMarks.SODOM] = {
			Marks = { CompletionType.BEAST },
			Name = "Beast",
			Difficulty = 1,
			Type = "Item",
			Condition = function(mark)
				return not pgd:Unlocked(Enums.Achievements.CompletionMarks.SODOM)
					and Isaac.GetCompletionMark(Enums.PlayerType.EDITH, CompletionType.BEAST) > 0
			end,
		},
		[Enums.Achievements.CompletionMarks.SOUL_EDITH] = {
			Name = "All Marks",
			Type = "Card",
			Condition = function()
				return not pgd:Unlocked(Enums.Achievements.CompletionMarks.SOUL_EDITH)
					and Isaac.AllMarksFilled(Enums.PlayerType.EDITH) == 2
			end,
		},
	},
	--[[BSide = {
		[Enums.Achievements.CompletionMarks.ELECTRIFIER] = {
			Name = "Mega Satan",
			Difficulty = 2,
			Marks = { CompletionType.MEGA_SATAN },
			Condition = function(mark)
				return not pgd:Unlocked(EdithRestored.Enums.Achievements.CompletionMarks.SOUL_EDITH)
					and Isaac.GetCompletionMark(Enums.PlayerType.EDITH, CompletionType.MEGA_SATAN) > 1
			end,
			ExtraData = function(elem)
				ImGui.SetHelpmarker(elem, "Unlocks Electrifier")
			end,
		},
		[Enums.Achievements.CompletionMarks.REV_PRUDENCE] = {
			Name = "Ultra Greedier",
			Difficulty = 2,
			Type = "Card",
			Marks = { CompletionType.ULTRA_GREEDIER },
			Condition = function(mark)
				return not pgd:Unlocked(EdithRestored.Enums.Achievements.CompletionMarks.SOUL_EDITH)
					and Isaac.GetCompletionMark(Enums.PlayerType.EDITH, CompletionType.ULTRA_GREEDIER) > 1
			end,
		},
		[Enums.Achievements.CompletionMarks.SOUL_EDITH] = {
			Name = "Hush/Boss Rush",
			Difficulty = 2,
			Type = "Card",
			Marks = { CompletionType.HUSH, CompletionType.BOSS_RUSH },
			Condition = function(mark)
				return not pgd:Unlocked(EdithRestored.Enums.Achievements.CompletionMarks.SOUL_EDITH)
					and Isaac.GetCompletionMark(Enums.PlayerType.EDITH_B, CompletionType.HUSH) > 1
					and Isaac.GetCompletionMark(Enums.PlayerType.EDITH_B, CompletionType.BOSS_RUSH) > 1
			end,
		},
		[Enums.Achievements.CompletionMarks.PEPPER_GRINDER] = {
			Name = "Isaac/Satan/Blue Baby/Lamb",
			Difficulty = 2,
			Type = "Trinket",
			Marks = { CompletionType.ISAAC, CompletionType.SATAN, CompletionType.BLUE_BABY, CompletionType.LAMB },
			Condition = function(mark)
				return not pgd:Unlocked(EdithRestored.Enums.Achievements.CompletionMarks.PEPPER_GRINDER)
					and Isaac.GetCompletionMark(Enums.PlayerType.EDITH_B, CompletionType.ISAAC) > 1
					and Isaac.GetCompletionMark(Enums.PlayerType.EDITH_B, CompletionType.SATAN) > 1
					and Isaac.GetCompletionMark(Enums.PlayerType.EDITH_B, CompletionType.BLUE_BABY) > 1
					and Isaac.GetCompletionMark(Enums.PlayerType.EDITH_B, CompletionType.LAMB) > 1
			end,
		},
	},]]
	Challenges = {
		[Enums.Achievements.Challenges.PEPPERMINT] = {
			Name = "Rocket Laces",
			Type = "Item",
			Condition = function()
				return not pgd:Unlocked(Enums.Achievements.Challenges.PEPPERMINT)
			end,
			Function = function(mark)
				if mark > 0 and not pgd:Unlocked(Enums.Achievements.Misc.ROCKET_LACES) then
					Isaac.ExecuteCommand("achievement " .. Enums.Achievements.Misc.ROCKET_LACES)
				end
			end,
		},
	},
	Misc = {
		[Enums.Achievements.Misc.ROCKET_LACES] = {
			Condition = function()
				return pgd:Unlocked(EdithRestored.Enums.Achievements.CompletionMarks.BLASTING_BOOTS)
					and not pgd:Unlocked(EdithRestored.Enums.Achievements.Misc.ROCKET_LACES)
			end,
		},
	},
	Characters = {
		[Enums.Achievements.Characters.EDITH] = {
			Name = "Edith",
			Condition = function()
				return pgd:IsBossKilled(BossType.BEAST)
					and not pgd:Unlocked(EdithRestored.Enums.Achievements.Characters.EDITH)
			end,
		},
	},
}

EdithRestored.Enums = Enums

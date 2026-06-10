EdithRestored:AddModCompat("Encyclopedia", function()
	local modname = "Restored Edith"
	local classname = "Restored Mods"

	local function Edith()
		return EdithRestored.PGD:Unlocked(EdithRestored.Enums.Achievements.Characters.EDITH) and "Edith"
			or "?????"
	end

	local Wiki = {
		Item = {
			SaltShaker = {
				ModName = modname,
				Class = classname,
				Name = "Salt Shaker",
				ID = EdithRestored.Enums.CollectibleType.COLLECTIBLE_SALT_SHAKER,
				Pools = {
					Encyclopedia.ItemPools.POOL_TREASURE,
					Encyclopedia.ItemPools.POOL_GREED_TREASURE,
				},
				UnlockFunc = function(self)
					if
						not EdithRestored.PGD
							:Unlocked(EdithRestored.Enums.Achievements.CompletionMarks.SALT_SHAKER)
					then
						self.Desc = "Unlocked by beating Isaac as " .. Edith()
						return self
					end
				end,
				WikiDesc = {
					{ -- Effect
						{ str = "Effect", fsize = 2, clr = 3, halign = 0 },
						{ str = "On use spawns a ring of salt creep near Isaac." },
						{ str = "Touching creep enemies are feared." },
					},
					--[[{ -- Notes
			{str = "Notes", fsize = 2, clr = 3, halign = 0},
			{str = "Placeholder text"},
		},]]
					{ -- Trivia
						{ str = "Trivia", fsize = 2, clr = 3, halign = 0 },
						{
							str = "Salt Shaker was one of the few items not imported into Repentance, alongside Book Of Despair, Bowl of Tears, Donkey Jawbone, Knife Piece 3, Menorah, and Voodoo Pin.",
						},
					},
				},
			},
			GorgonMask = {
				ModName = modname,
				Class = classname,
				Name = "Gorgon Mask",
				ID = EdithRestored.Enums.CollectibleType.COLLECTIBLE_GORGON_MASK,
				Pools = {
					Encyclopedia.ItemPools.POOL_TREASURE,
					Encyclopedia.ItemPools.POOL_GREED_TREASURE,
					Encyclopedia.ItemPools.POOL_CURSE,
					Encyclopedia.ItemPools.POOL_GREED_CURSE,
				},
				UnlockFunc = function(self)
					if
						not EdithRestored.PGD
							:Unlocked(EdithRestored.Enums.Achievements.CompletionMarks.GORGON_MASK)
					then
						self.Desc = "Unlocked by beating Ultra Greedier as " .. Edith()
						return self
					end
				end,
				WikiDesk = {
					{ -- Effect
						{ str = "Effect", fsize = 2, clr = 3, halign = 0 },
						{ str = "On use puts on/off Gorgon mask." },
						{ str = "Looking at enemies when mask is on freezes them." },
						{ str = "Isaac can't shoot while mask is on." },
					},
					{ -- Trivia
						{ str = "Trivia", fsize = 2, clr = 3, halign = 0 },
						{ str = "Gorgon Mask is based on head of Medusa, a character in Greek mythological." },
					},
				},
			},
			ThunderBombs = {
				ModName = modname,
				Class = classname,
				Name = "Thunder Bombs",
				ID = EdithRestored.Enums.CollectibleType.COLLECTIBLE_THUNDER_BOMBS,
				Pools = {
					Encyclopedia.ItemPools.POOL_TREASURE,
					Encyclopedia.ItemPools.POOL_SHOP,
					Encyclopedia.ItemPools.POOL_GREED_TREASURE,
					Encyclopedia.ItemPools.POOL_BOMB_BUM,
					Encyclopedia.ItemPools.POOL_BATTERY_BUM,
				},
				UnlockFunc = function(self)
					if
						not EdithRestored.PGD
							:Unlocked(EdithRestored.Enums.Achievements.CompletionMarks.THUNDER_BOMBS)
					then
						self.Desc = "Unlocked by beating ??? as " .. Edith()
						return self
					end
				end,
				WikiDesc = {
					{ -- Effect
						{ str = "Effect", fsize = 2, clr = 3, halign = 0 },
						{ str = "Fully recharges active items." },
						{ str = "When Isaac has no bombs, one can be placed at the cost of a charge." },
						{ str = "Bombs make electricity that spreads to nearby enemies and does half bomb's damage." },
					},
					{ -- Trivia
						{ str = "Trivia", fsize = 2, clr = 3, halign = 0 },
						{ str = "Thunder bombs was an unused idea from Antibirth, it only existed in concept art." },
					},
				},
			},
			LithiumSalts = {
				ModName = modname,
				Class = classname,
				Name = "Lithium Salts",
				ID = EdithRestored.Enums.CollectibleType.COLLECTIBLE_LITHIUM,
				UnlockFunc = function(self)
					if
						not EdithRestored.PGD
							:Unlocked(EdithRestored.Enums.Achievements.CompletionMarks.LITHIUM)
					then
						self.Desc = "Unlocked by beating Delirium as " .. Edith()
						return self
					end
				end,
				Pools = {
					Encyclopedia.ItemPools.POOL_CURSE,
					Encyclopedia.ItemPools.POOL_GREED_CURSE,
					Encyclopedia.ItemPools.POOL_SHOP,
					Encyclopedia.ItemPools.POOL_GREED_SHOP,
					Encyclopedia.ItemPools.POOL_DEMON_BEGGAR,
				},
				WikiDesc = {
					{ -- Effect
						{ str = "Effect", fsize = 2, clr = 3, halign = 0 },
						{ str = "Adds extra Lithium pill that can with 10% chance replace normal pills." },
						{ str = "Decreases one random stat." },
						{ str = "+20 frames of invincibility per use when taking damage." },
					},
					{ -- Synergies
						{ str = "Synergies", fsize = 2, clr = 3, halign = 0 },
						{ str = "Horse Pills - effect is doubled." },
						{ str = "Synergies", fsize = 2, clr = 3, halign = 0 },
						{ str = "PHD - no negative effects when using Lithium pills." },
						{ str = "False PHD:" },
						{ str = "- -0.05 extra damage per use." },
						{ str = "- -0.01 extratear rate per use." },
						{ str = "- +5 extra frames of invincibility per use when taking damage." },
					},
					--[[{ -- Trivia
			{str = "Trivia", fsize = 2, clr = 3, halign = 0},
			{str = ""},
		},]]
				},
			},
			BlastingBoots = {
				ModName = modname,
				Class = classname,
				Name = "Blasting Boots",
				ID = EdithRestored.Enums.CollectibleType.COLLECTIBLE_BLASTING_BOOTS,
				Pools = {
					Encyclopedia.ItemPools.POOL_TREASURE,
					Encyclopedia.ItemPools.POOL_GREED_SHOP,
					Encyclopedia.ItemPools.POOL_CRANE_GAME,
					Encyclopedia.ItemPools.POOL_BOMB_BUM,
				},
				UnlockFunc = function(self)
					if
						not EdithRestored.PGD
							:Unlocked(EdithRestored.Enums.Achievements.CompletionMarks.BLASTING_BOOTS)
					then
						self.Desc = "Unlocked by beating Hush as " .. Edith()
						return self
					end
				end,
				WikiDesc = {
					{ -- Effect
						{ str = "Effect", fsize = 2, clr = 3, halign = 0 },
						{ str = "Gives explosion immunity." },
						{ str = "Explosions launches Isaac in the air." },
					},
					{ -- Synergies
						{ str = "Synergies", fsize = 2, clr = 3, halign = 0 },
						{ str = "Edith - on landing procs Edith's stomp effect." },
					},
					{ -- Notes
						{ str = "Notes", fsize = 2, clr = 3, halign = 0 },
						{ str = "When Isaac launched, he can go over pits and and rocks." },
						{ str = "Falling into pit brings Isaac back to nearest solid ground." },
						--{ str = "Falling into pit as Edith makes you land like you would do a stomp jump." },
					},
					--[[{ -- Trivia
			{str = "Trivia", fsize = 2, clr = 3, halign = 0},
			{str = ""},
		},]]
				},
			},
			PawnBaby = {
				ModName = modname,
				Class = classname,
				Name = "Pawn Baby",
				ID = EdithRestored.Enums.CollectibleType.COLLECTIBLE_SALT_PAWNS,
				Pools = {
					Encyclopedia.ItemPools.POOL_SHOP,
					Encyclopedia.ItemPools.POOL_GREED_SHOP,
					Encyclopedia.ItemPools.POOL_SECRET,
					Encyclopedia.ItemPools.POOL_GREED_SECRET,
					Encyclopedia.ItemPools.POOL_WOODEN_CHEST,
					Encyclopedia.ItemPools.POOL_BABY_SHOP,
				},
				UnlockFunc = function(self)
					if
						not EdithRestored.PGD
							:Unlocked(EdithRestored.Enums.Achievements.CompletionMarks.SALT_PAWNS)
					then
						self.Desc = "Unlocked by beating Ultra Greed as " .. Edith()
						return self
					end
				end,
				WikiDesc = {
					{ -- Effect
						{ str = "Effect", fsize = 2, clr = 3, halign = 0 },
						{
							str = "Spawns a pawn familiar that travels foward one tile at a time, starting from the door the room was entered from.",
						},
						{ str = "Stomps on nearby enemies for 30 damage." },
						{ str = "Respawns at a random door after reaching a wall." },
					},
					{ -- Synergies
						{ str = "Synergies", fsize = 2, clr = 3, halign = 0 },
						{ str = "BFFS! - damage is doubled." },
					},
					{ -- Trivia
						{ str = "Trivia", fsize = 2, clr = 3, halign = 0 },
						{
							str = "This item's effects are based off of the Checked Mate item from Antibirth.",
						},
					},
				},
			},
			SaltyBaby = {
				ModName = modname,
				Class = classname,
				Name = "Salty Baby",
				ID = EdithRestored.Enums.CollectibleType.COLLECTIBLE_SALTY_BABY,
				Pools = {
					Encyclopedia.ItemPools.POOL_SHOP,
					Encyclopedia.ItemPools.POOL_GREED_SHOP,
					Encyclopedia.ItemPools.POOL_GOLDEN_CHEST,
					Encyclopedia.ItemPools.POOL_BABY_SHOP,
				},
				UnlockFunc = function(self)
					if
						not EdithRestored.PGD
							:Unlocked(EdithRestored.Enums.Achievements.CompletionMarks.SALTY_BABY)
					then
						self.Desc = "Unlocked by beating Mom's Heart/It Lives as " .. Edith()
						return self
					end
				end,
				WikiDesc = {
					{ -- Effect
						{ str = "Effect", fsize = 2, clr = 3, halign = 0 },
						{ str = "Familiar that fires salt rock projectiles when getting hit by an enemy tear." },
						{
							str = "After blocking 6 enemy tears, loses the ability to block shots and leaves a trail of fearing salt creep instead.",
						},
						{ str = "In broken state shoots projectiles every 5-7 seconds." },
						{ str = "Returns to its original state at the start of every floor." },
					},
					{ -- Synergies
						{ str = "Synergies", fsize = 2, clr = 3, halign = 0 },
						{ str = "BFFS! - slaty rock projectiles deal x1.25 more damage." },
						{ str = "BFFS! - can block 8 enemy tears." },
						{ str = "BFFS! - salt creep is larger." },
					},
					{ -- Trivia
						{ str = "Trivia", fsize = 2, clr = 3, halign = 0 },
						{
							str = "Originally was supposed to be a co-op baby, but was made as familiar instead.",
						},
					},
				},
			},
			Sodom = {
				ModName = modname,
				Class = classname,
				Name = "Sodom",
				ID = EdithRestored.Enums.CollectibleType.COLLECTIBLE_SODOM,
				Pools = {
					Encyclopedia.ItemPools.POOL_DEVIL,
					Encyclopedia.ItemPools.POOL_GREED_DEVIL,
				},
				UnlockFunc = function(self)
					if
						not EdithRestored.PGD
							:Unlocked(EdithRestored.Enums.Achievements.CompletionMarks.SODOM)
					then
						local line = "the Beast"
						if
							EdithRestored.PGD:GetBestiaryEncounterCount(EntityType.ENTITY_BEAST, -1) == 0
						then
							line = "??? ?????"
						end
						self.Desc = "Unlocked by beating " .. line .. " as " .. Edith()
						return self
					end
				end,
				WikiDesc = {
					{ -- Effect
						{ str = "Effect", fsize = 2, clr = 3, halign = 0 },
						{ str = "Every second when moving Isaac shoots flame." },
						{ str = "Flame goes opposite direction of Isaac's movement." },
						{
							str = "Flame doesn't damage enemies, but applies burn effect, that deals 80% Isaac's damage.",
						},
						{ str = "On death with effect enemies shoot 8 flames with same effect." },
						{ str = "Effect can be applied to enemy only one time." },
					},
					{ -- Trivia
						{ str = "Trivia", fsize = 2, clr = 3, halign = 0 },
						{
							str = "Sodom is a biblical city alongside Gomorrah that was destroyed by God for their wickedness.",
						},
						{ str = "Item icon references city's destruction by 'sulfur and fire'." },
					},
				},
			},
			RedHood = {
				ModName = modname,
				Class = classname,
				Name = "Red Hood",
				ID = EdithRestored.Enums.CollectibleType.COLLECTIBLE_RED_HOOD,
				Pools = {
					Encyclopedia.ItemPools.POOL_TREASURE,
					Encyclopedia.ItemPools.POOL_GREED_TREASURE,
					Encyclopedia.ItemPools.POOL_GREED_SECRET,
					Encyclopedia.ItemPools.POOL_SECRET,
					Encyclopedia.ItemPools.POOL_ULTRA_SECRET,
				},
				UnlockFunc = function(self)
					if
						not EdithRestored.PGD
							:Unlocked(EdithRestored.Enums.Achievements.CompletionMarks.RED_HOOD)
					then
						self.Desc = "Unlocked by completing Boss Rush as" .. Edith()
						return self
					end
				end,
				WikiDesc = {
					{ -- Effect
						{ str = "Effect", fsize = 2, clr = 3, halign = 0 },
						{ str = "Cycle between moon phases on room clear" },
						{ str = "Increased stats the closer the phase is to a full moon." },
						{ str = "On full moon, gain extra stat boosts, contact damage, and stompy effect." },
						{ str = "Full Moon bonuses are always active in floors with Curse of Darkness" },
					},
					{ -- Trivia
						{ str = "Trivia", fsize = 2, clr = 3, halign = 0 },
						{
							str = "This item is a reference to Little Red Riding Hood.",
						},
					},
				},
			},
			ShrapnelBombs = {
				ModName = modname,
				Class = classname,
				Name = "Shrapnel Bombs",
				ID = EdithRestored.Enums.CollectibleType.COLLECTIBLE_SHRAPNEL_BOMBS,
				Pools = {
					Encyclopedia.ItemPools.POOL_TREASURE,
					Encyclopedia.ItemPools.POOL_GREED_TREASURE,
					Encyclopedia.ItemPools.POOL_BOMB_BUM,
					Encyclopedia.ItemPools.POOL_GREED_SHOP,
				},
				UnlockFunc = function(self)
					if
						not EdithRestored.PGD
							:Unlocked(EdithRestored.Enums.Achievements.CompletionMarks.SHRAPNEL_BOMBS)
					then
						self.Desc = "Unlocked by beating Mother" .. Edith()
						return self
					end
				end,
				WikiDesc = {
					{ -- Effect
						{ str = "Effect", fsize = 2, clr = 3, halign = 0 },
						{ str = "+5 Bombs" },
						{ str = "Isaac's bombs fire high velocity nails in random directions upon detonating" },
						{ str = "Nails pierce enemies and inflict bleeding" },
					},
					{ -- Trivia
						{ str = "Trivia", fsize = 2, clr = 3, halign = 0 },
						{
							str = "",
						},
					},
				},
			},
			Peppermint = {
				ModName = modname,
				Class = classname,
				Name = "Peppermint",
				ID = EdithRestored.Enums.CollectibleType.COLLECTIBLE_PEPPERMINT,
				Pools = {
					Encyclopedia.ItemPools.POOL_TREASURE,
					Encyclopedia.ItemPools.POOL_GREED_TREASURE,
					Encyclopedia.ItemPools.POOL_ULTRA_SECRET,
					Encyclopedia.ItemPools.POOL_CRANE_GAME,
				},
				UnlockFunc = function(self)
					if
						not EdithRestored.PGD
							:Unlocked(EdithRestored.Enums.Achievements.CompletionMarks.PEPPERMINT)
					then
						self.Desc = "Unlocked by beating Rocket Laces challenge"
						return self
					end
				end,
				WikiDesc = {
					{ -- Effect
						{ str = "Effect", fsize = 2, clr = 3, halign = 0 },
						{ str = "Adds an extra charge bar that charges while firing." },
						{
							str = "After 7 seconds, releasing the fire button launches a mint cloud in the direction Isaac is firing.",
						},
						{
							str = "The cloud moves similar to Linger Bean gas, but will always try to advance forward until it hits the end of the room.",
						},
						{ str = "Enemies in the cloud are slowed and take a small amount of damage per tick." },
						{ str = "Enemies dying in the cloud are frozen." },
					},
					{ -- Synergies
						{ str = "Synergies", fsize = 2, clr = 3, halign = 0 },
						{ str = "" },
					},
					{ -- Trivia
						{ str = "Trivia", fsize = 2, clr = 3, halign = 0 },
						{
							str = "",
						},
					},
				},
			},
		},

		Trinket = {
			--Smelling Salts
			SmellingSalts = {
				ModName = modname,
				Class = classname,
				Name = "Smelling Salts",
				ID = EdithRestored.Enums.TrinketType.TRINKET_SMELLING_SALTS,
				UnlockFunc = function(self)
					if
						not EdithRestored.PGD
							:Unlocked(EdithRestored.Enums.Achievements.CompletionMarks.SMELLING_SALTS)
					then
						self.Desc = "Unlocked by beating the Lamb as " .. Edith()
						return self
					end
				end,
				WikiDesc = {
					{ -- Effect
						{ str = "Effect", fsize = 2, clr = 3, halign = 0 },
						{
							str = "Enemies inflicted with slow or petrified are instantly cleansed of the debuff, and are instead given the weakness debuff (from reverse strength)",
						},
					},
				},
			},
			--Salt Rock
			SaltRock = {
				ModName = modname,
				Class = classname,
				Name = "Smelling Salts",
				ID = EdithRestored.Enums.TrinketType.TRINKET_SALT_ROCK,
				UnlockFunc = function(self)
					if
						not EdithRestored.PGD
							:Unlocked(EdithRestored.Enums.Achievements.CompletionMarks.SALT_ROCK)
					then
						self.Desc = "Unlocked by beating ??? ?????"
						return self
					end
				end,
				WikiDesc = {
					{ -- Effect
						{ str = "Effect", fsize = 2, clr = 3, halign = 0 },
						{ str = "Rocks have a chance to emit a pool of salt creep upon entering an uncleared room." },
						{ str = "Salt Rocks fire rock tears in all directions upon being destroyed." },
					},
				},
			},
			--Chunk of Amber
			ChunkOfAmber = {
				ModName = modname,
				Class = classname,
				Name = "Chunk of Amber",
				ID = EdithRestored.Enums.TrinketType.TRINKET_CHUNK_OF_AMBER,
				UnlockFunc = function(self)
					if
						not EdithRestored.PGD
							:Unlocked(EdithRestored.Enums.Achievements.CompletionMarks.CHUNK_OF_AMBER)
					then
						self.Desc = "Unlocked by beating Satan as " .. Edith()
						return self
					end
				end,
				WikiDesc = {
					{ -- Effect
						{ str = "Effect", fsize = 2, clr = 3, halign = 0 },
						{ str = "Petrified enemies spawn either a random pickup, blue spider, or blue fly on death." },
					},
				},
			},
		},
		Pill = {
			Lithium = {
				ModName = modname,
				Class = classname,
				Spr = Encyclopedia.RegisterSprite("gfx/ui/encyclopedia_edith_cardspills.anm2", "Pills", 0),
				ID = EdithRestored.Enums.Pickups.PillEffects.PILLEFFECT_LITHIUM,
				WikiDesc = {
					{ -- Effect
						{ str = "Effect", fsize = 2, clr = 3, halign = 0 },
						{ str = "Decreases one random stat." },
						{ str = "Gives additional 20 invincibility frames." },
					},
					{ -- Synergies
						{ str = "Synergies", fsize = 2, clr = 3, halign = 0 },
						{ str = "False PHD! - increases damage." },
						{ str = "False PHD! - extra 5 invincibility frames." },
					},
				},
				UnlockFunc = function(self)
					if
						not EdithRestored.PGD
							:Unlocked(EdithRestored.Enums.Achievements.CompletionMarks.LITHIUM)
					then
						self.Desc = "Unlocked by beating Delirium as " .. Edith()
						return self
					end
				end,
				Description = "Negative?",
			},
		},
		Soul = {
			SoulOfEdith = {
				ModName = modname,
				Class = classname,
				ID = EdithRestored.Enums.Pickups.Cards.CARD_SOUL_EDITH,
				WikiDesc = {
					{ -- Effect
						{ str = "Effect", fsize = 2, clr = 3, halign = 0 },
						{ str = "Turn Isaac into statue that stomps enemies 4 times." },
						{ str = "If no enemies in a room then jumps in place." },
					},
					{ -- Synergies
						{ str = "Synergies", fsize = 2, clr = 3, halign = 0 },
						{ str = "Clear Rune + Car Battery - Isaac stomps 5 times instead of 4." },
					},
				},
				UnlockFunc = function(self)
					if
						not EdithRestored.PGD
							:Unlocked(EdithRestored.Enums.Achievements.CompletionMarks.SOUL_EDITH)
					then
						self.Desc = "Unlocked by getting all completion marks as " .. Edith()
						return self
					end
				end,
			},
		},
		Character = {
			Edith = {
				ModName = modname,
				Name = "Edith",
				ID = EdithRestored.Enums.PlayerType.EDITH,
				Sprite = Encyclopedia.RegisterSprite(
					EdithRestored.path .. "content/gfx/characterportraits.anm2",
					"Redith",
					0
				),
				UnlockFunc = function(self)
					if
						not EdithRestored.PGD:Unlocked(EdithRestored.Enums.Achievements.Characters.EDITH)
					then
						self.Desc = "Unlocked by beating ??? ?????"
						return self
					end
				end,
				WikiDesc = {
					{ -- Start Data
						{ str = "Start Data", fsize = 2, clr = 3, halign = 0 },
						{ str = "Items:" },
						{ str = "- Salt Shaker (after unlocking)" },
						{ str = "Stats:" },
						{ str = "- HP: 3 Soul Hearts" },
						{ str = "- Speed: 1.00" },
						{ str = "- Tear rate: 2.73" },
						{ str = "- Damage: 3.85" },
						{ str = "- Range: 6.05" },
						{ str = "- Shot speed: 1.00" },
						{ str = "- Luck: 0.00" },
					},
					{ -- Traits
						{ str = "Traits", fsize = 2, clr = 3, halign = 0 },
						{
							str = "Edith cannot gain red heart containers. If an item would grant her a red heart container (including an empty one), it adds a soul heart instead.",
						},
						{ str = "Edith cannot walk around freely, and instead slides in cardinal direction." },
						{
							str = "Pressing the bomb key (E by default) with full charge will create a target radical that can be moved with shooting buttons.",
						},
						{
							str = "Pressing it again will make Edith jump to that position, damaging enemies and destroing rocks on landing.",
						},
						{ str = "Pressing the drop key (ctrl by default) will switch to/from bomb landing." },
						{
							str = "If player has any bombs or golden bomb, explosion will happen on landing, damaging only enemies.",
						},
					},
					{ -- Birthright
						{ str = "Birthright", fsize = 2, clr = 3, halign = 0 },
						{ str = "Jump charges faster." },
						{ str = "Moving doesn't slow jump charging." },
						{ str = "Increases knockback. Knockbacked enemies take damage when collide with obstacles." },
					},
					{ -- Notes
						{ str = "Notes", fsize = 2, clr = 3, halign = 0 },
						{ str = "Damage from landing is affected by Edith's damage." },
						{ str = "Bomb landing has the same effects as bomb items effects." },
					},
					{ -- Trivia
						{ str = "Trivia", fsize = 2, clr = 3, halign = 0 },
						{
							str = "Edith was unused and unfinished character in Antibirth mod, that eventually became Tainted Forgotten.",
						},
					},
				},
			},
		},
	}

	for fn, tp in pairs(Wiki) do
		for k, v in pairs(tp) do
			Encyclopedia["Add" .. fn](v)
		end
	end

	EdithRestored.Enums.Wiki = Wiki
end)

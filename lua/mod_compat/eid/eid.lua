if not EID then
	return
end

local game = EdithRestored.Game

local iconSprite = Sprite("gfx/ui/eid_edith_icon.anm2", true)

local PlayerIconSprite = Sprite("gfx/ui/eid_edith_players_icons.anm2", true)

local CardsPillsIconsSprite = Sprite("gfx/ui/eid_edith_cardspills_icons.anm2", true)

local SoulOfEdithIconName = "Card" .. EdithRestored.Enums.Pickups.Cards.CARD_SOUL_EDITH
local LithiumPillIconName = "Pill" .. EdithRestored.Enums.Pickups.Pills.PILL_LITHIUM

-- Mod Icon (TODO)
local function HodlingTab()
	return EID.Config["ItemReminderEnabled"]
		and EID.holdTabCounter >= 30
		and EID.TabDescThisFrame == false
		and EID.holdTabPlayer ~= nil
end

EID:setModIndicatorName("Edith")

EID:addIcon("Edith Icon", "EdithIcon", 0, 15, 24, 6, 6, iconSprite)
EID:setModIndicatorIcon("Edith Icon")

-- Birthright Icons

EID:addIcon("Player" .. EdithRestored.Enums.PlayerType.EDITH, "Edith", 0, 12, 12, -1, 1, PlayerIconSprite)

EID:addIcon(SoulOfEdithIconName, "Cards", 0, 12, 12, 0, 0, CardsPillsIconsSprite)
EID:addIcon(LithiumPillIconName, "Pills", 0, 12, 12, 0, 0, CardsPillsIconsSprite)

EID:AddIconToObject(
	EntityType.ENTITY_PICKUP,
	PickupVariant.PICKUP_TAROTCARD,
	EdithRestored.Enums.Pickups.Cards.CARD_SOUL_EDITH,
	SoulOfEdithIconName
)
EID:AddIconToObject(
	EntityType.ENTITY_PICKUP,
	PickupVariant.PICKUP_PILL,
	EdithRestored.Enums.Pickups.Pills.PILL_LITHIUM,
	LithiumPillIconName
)
EID:AddIconToObject(
	EntityType.ENTITY_PICKUP,
	PickupVariant.PICKUP_PILL,
	EdithRestored.Enums.Pickups.Pills.PILL_HORSE_LITHIUM,
	LithiumPillIconName
)

-- Edith
EID:addBirthright(
	EdithRestored.Enums.PlayerType.EDITH,
	"{{Charge}} Jump charges faster#Moving doesn't slow jump charging#Stomp has increased knockback that damages enemies when they collide with obstacles",
	"Edith",
	"en_us"
)
EID:addBirthright(
	EdithRestored.Enums.PlayerType.EDITH,
	"{{Charge}} Прыжок заряжается быстрее#Передвигаясь заряд прыжка не замедляется#Отбрасывание от презимления увеличено и наносит урон врагам, когда они сталкиваются со стеной/препятствием",
	"Эдит",
	"ru"
)
--EID:addBirthright(EdithRestored.Enums.PlayerType.EDITH, "La carga del salto será más rápida y no se detendrá al moverse", "Edith", "es")

-- Items

--Salt Shaker
EID:addCollectible(
	EdithRestored.Enums.CollectibleType.COLLECTIBLE_SALT_SHAKER,
	"On use creates ring of salt creep near Isaac#Enemies coming close to it get {{Fear}} fear effect",
	"Salt Shaker"
)
EID:addCollectible(
	EdithRestored.Enums.CollectibleType.COLLECTIBLE_SALT_SHAKER,
	"При использовании создает круг из соли рядом с Айзеком#Враги, приближающиеся к нему, получают {{Fear}} эффект страха",
	"Солонка",
	"ru"
)

--Gorgon Mask
EID:addCollectible(
	EdithRestored.Enums.CollectibleType.COLLECTIBLE_GORGON_MASK,
	"On use puts on/off Gorgon mask#When mask is on, Isaac can't shoot#{{Petrify}} Looking at enemies, when Isaac has mask on freezes them",
	"Gorgon Mask"
)
EID:addCollectible(
	EdithRestored.Enums.CollectibleType.COLLECTIBLE_GORGON_MASK,
	"При использовании одевает/снимает маску Горгоны#Когда маска одета, Айзек не может стрелять#{{Petrify}} Глядя на врагов, когда Айзек в маске, они каменеют",
	"Маска Горгоны",
	"ru"
)

--Lithium Salts
--EID:addCollectible(EdithRestored.Enums.CollectibleType.COLLECTIBLE_LITHIUM, "Todas las píldoras reducirán el daño y las lágrimas, pero aumentarán el tiempo de invencibilidad", "Sales de litio", "es")
EID:addCollectible(
	EdithRestored.Enums.CollectibleType.COLLECTIBLE_LITHIUM,
	"Pills have a 10% chance to be replaced by Lithium Pills#{{"
		.. LithiumPillIconName
		.. "}} Lithium Pills grant a random stat down, but increase Isaac's invincibility frames after getting hit",
	"Lithium Salts"
)
EID:addCollectible(
	EdithRestored.Enums.CollectibleType.COLLECTIBLE_LITHIUM,
	"10% шанс пилюли заменятся литийными таблетками#{{"
		.. LithiumPillIconName
		.. "}} Литийные таблетки понижают случайную статистику, но увеличивают кадры неуязвимости Айзека после получения удара",
	"Литивые соли",
	"ru"
)

--Thunder Bombs
EID:addCollectible(
	EdithRestored.Enums.CollectibleType.COLLECTIBLE_THUNDER_BOMBS,
	"{{Battery}} Fully recharges active items#{{Battery}} When Isaac has no bombs, one can be placed at the cost of three charges#Bombs make electricity that spreads to nearby enemies#Electricity deals half of the bomb's damage",
	"Thunder Bombs",
	"en_us"
)
EID:addCollectible(
	EdithRestored.Enums.CollectibleType.COLLECTIBLE_THUNDER_BOMBS,
	"{{Battery}} Полностью заряжает активные предметы#{{Battery}} Когда у Айзека нет бомб, одна может быть использована взамен на заряд#Бомбы создают электричество, которое распространяется на близлежащих врагов#Електричество наносит половину урона от бомб",
	"Громовые бомбы",
	"ru"
)

--Blasting Boots
EID:addCollectible(
	EdithRestored.Enums.CollectibleType.COLLECTIBLE_BLASTING_BOOTS,
	"{{Bomb}} +5 bombs#Gives explosion immunity#Explosion launches Isaac in the air",
	"Blasting Boots",
	"en_us"
)
EID:addCollectible(
	EdithRestored.Enums.CollectibleType.COLLECTIBLE_BLASTING_BOOTS,
	"{{Bomb}} +5 бомб#Дает устойчивость ко взрывам#Взрыв подбрасывет Айзека в воздух",
	"Взрывостойкие сапоги",
	"ru"
)

--Pawn Baby
EID:addCollectible(
	EdithRestored.Enums.CollectibleType.COLLECTIBLE_SALT_PAWNS,
	"Spawns a pawn familiar that travels forward one tile at a time, starting from the door the room was entered from#Stomps on nearby enemies for 30 damage#Respawns at a random door after reaching a wall",
	"Salt Pawns",
	"en_us"
)
EID:addCollectible(
	EdithRestored.Enums.CollectibleType.COLLECTIBLE_SALT_PAWNS,
	"Дает пешку-фамильяра, которая передвигается вперед на один тайл за раз, начиная с двери, с которой вошли в комнату#Прыгает на ближайших врагов, нанося 30 единиц урона#Появляется у случайной двери после столкновения со стеной",
	"Соленая пешка",
	"ru"
)

--Salty Baby
EID:addCollectible(
	EdithRestored.Enums.CollectibleType.COLLECTIBLE_SALTY_BABY,
	"Familiar that fires salt rock projectiles when getting hit by an enemy tear# After blocking 6 enemy tears, loses the ability to block shots and leaves a trail of fearing salt creep instead#Returns to its original state at the start of every floor",
	"Salty Baby",
	"en_us"
)
EID:addCollectible(
	EdithRestored.Enums.CollectibleType.COLLECTIBLE_SALTY_BABY,
	"Фамильяр, котрый стреляет соляными снарядами при получении урона от слез врага# Заблокировав 6 слез врагов перестает блокировать снаряды и вместо этого оставляет следы отпугивающей соли#Возвращается в исходное состояние при старте каждого этажа",
	"Малыш-солонка",
	"ru"
)

--Sodom
EID:addCollectible(
	EdithRestored.Enums.CollectibleType.COLLECTIBLE_SODOM,
	"Every second when Isaac moves he shoots a red flame opposite of his movement direction#Flame doesn't damage enemies but applies a {{Burning}} burn effect on them that deals 80% of Isaac's damage#Burning enemies shoots flames in 3 directions on death",
	"Sodom",
	"en_us"
)
EID:addCollectible(
	EdithRestored.Enums.CollectibleType.COLLECTIBLE_SODOM,
	"Каждую секунду Айзек, когда передвигается, выстреливает в противоположном направлении движения красное пламя#Пламя не наносит урона врагам, но накладывает на них эффект {{Burning}} горения, который наносит 80% урона Айзека#Горящие враги выстреливают пламя в 3 направлениях при смерти",
	"Содом",
	"ru"
)

--Shrapnel Bombs
EID:addCollectible(
	EdithRestored.Enums.CollectibleType.COLLECTIBLE_SHRAPNEL_BOMBS,
	"{{Bomb}} +5 bombs#Isaac's bombs fire high velocity nails in random directions upon detonating#{{BleedingOut}} Nails pierce enemies and inflict bleeding",
	"Shrapnel Bombs",
	"en_us"
)
EID:addCollectible(
	EdithRestored.Enums.CollectibleType.COLLECTIBLE_SHRAPNEL_BOMBS,
	"{{Bomb}} +5 бомб#Бомбы Айзека выстреливают высокоскоростными гвоздями в случайных направлениях при детонировании#{{BleedingOut}} Гвозди проходят сквозь врагов и накладывают эффект кровотечения",
	"Шрапнельные бомбы",
	"ru"
)

--Red Hood
EID:addCollectible(
	EdithRestored.Enums.CollectibleType.COLLECTIBLE_RED_HOOD,
	"Cycles between moon phases on room clear#Increased stats the closer the phase is to a full moon#On full moon, gain extra stat boosts, contact damage, and {{Stompy}} Stompy effect",
	"Red Hood",
	"en_us"
)
EID:addCollectible(
	EdithRestored.Enums.CollectibleType.COLLECTIBLE_RED_HOOD,
	"Меняет фазы луны при зачистке комнаты#Увеличивает характеристики, чем ближе к фаза полнолуния#При полной луне получает сильное увеличение характеристик, контактный урон и {{Stompy}} эффект Топтуна",
	"Красная шапочка",
	"ru"
)

--Peppermint
EID:addCollectible(
	EdithRestored.Enums.CollectibleType.COLLECTIBLE_PEPPERMINT,
	"{{Chargeable}} After firing for 7 seconds Isaac launches a mint cloud in the direction he was firing#{{Slow}} Enemies touching the cloud are slowed and take damage over time#{{Freezing}} Slowed by cloud enemies are frozen on death",
	"Peppermint",
	"en_us"
)
EID:addCollectible(
	EdithRestored.Enums.CollectibleType.COLLECTIBLE_PEPPERMINT,
	"{{Chargeable}} После 7 секунд стрельбы Айзек выпускает мятное облако в том направлении, в которое он стрелял#{{Slow}} Враги коснувшиеся облако замедлены и получают постепенный урон#{{Freezing}} Замедленные облаком враги замораживаются при смерти",
	"Перченая мята",
	"ru"
)

-- Trinkets

--Smelling Salts
EID:addTrinket(
	EdithRestored.Enums.TrinketType.TRINKET_SMELLING_SALTS,
	"All instances of {{Slow}} slow and {{Petrify}} petrify inflicted onto enemies is instead converted into weakness#{{Weakness}} Weakness decreases enemy speed and increases damage dealt to them",
	"Smelling Salts",
	"en_us"
)
EID:addTrinket(
	EdithRestored.Enums.TrinketType.TRINKET_SMELLING_SALTS,
	"Эффекты {{Slow}} замедления и {{Petrify}} окменения, наложенные на врагов, вместо этого преобразуются в слабость#{{Weakness}} Слабость снижает скорость врагов и увеличивает урон, наносимый им",
	"Нюхательная соль",
	"ru"
)

--Salt Rock
EID:addTrinket(
	EdithRestored.Enums.TrinketType.TRINKET_SALT_ROCK,
	"Rocks have a chance to emit a pool of salt creep upon entering an uncleared room#Salt Rocks fire rock tears in all directions upon being destroyed",
	"Salt Rock",
	"en_us"
)
EID:addTrinket(
	EdithRestored.Enums.TrinketType.TRINKET_SALT_ROCK,
	"У камней есть шанс создать бассейн из соляной лужи при входе в незачищенную комнату#Соляные камни выстреливают соляными снарядами во всех нарпавлениях после уничтожения",
	"Соляной камень",
	"ru"
)

--Chunk of Amber
EID:addTrinket(
	EdithRestored.Enums.TrinketType.TRINKET_CHUNK_OF_AMBER,
	"Petrified enemies spawn either a random pickup, blue spider, or blue fly on death",
	"Chunk of Amber"
)
EID:addTrinket(
	EdithRestored.Enums.TrinketType.TRINKET_CHUNK_OF_AMBER,
	"Закаменевшие враги создают при смерти случайный пикап, синиего паука или синию муху при смерти",
	"Кусок янтаря",
	"ru"
)

-- Cards/Runes/Pills

--Soul of Edith
EID:addCard(
	EdithRestored.Enums.Pickups.Cards.CARD_SOUL_EDITH,
	"Turns Isaac into a statue that stomps enemies 4 times#The fourth stomp causes an explosion that inherits all Isaac's bomb effects#Targets rocks instead of there are no enemies in the room",
	"Soul of Edith"
)
EID:addCard(
	EdithRestored.Enums.Pickups.Cards.CARD_SOUL_EDITH,
	"Превращает Айзека в статую, которая прыгает на врагов 4 раза#Четвертый прыжок создает взрыв, который наследует все эффекты бомб Айзека#Статуя прыгает на камни, если нет врагов в комнате",
	"Душа Эдит",
	"ru"
)

local soulEdithSynergy = {
	en_us = "Isaac stomps 5 times",
	ru = "Айзек прыгает 5 раз",
}

local function SoulEdithCondition(descObj)
	if
		descObj.ObjType == 5
		and descObj.ObjVariant == 300
		and descObj.ObjSubType == EdithRestored.Enums.Pickups.Cards.CARD_SOUL_EDITH
		and (descObj and descObj.Entity or HodlingTab())
	then
		return true
	end
	return false
end

local function SoulEdithCallback(descObj)
	local player
	if HodlingTab() then
		player = EID.holdTabPlayer
	elseif descObj and descObj.Entity then
		player = game:GetNearestPlayer(descObj.Entity.Position)
	end
	if
		player
		and player:HasCollectible(CollectibleType.COLLECTIBLE_CLEAR_RUNE)
		and player:HasCollectible(CollectibleType.COLLECTIBLE_CAR_BATTERY)
	then
		local synergy = soulEdithSynergy[EID:getLanguage()] or soulEdithSynergy["en_us"]
		descObj.Description = descObj.Description .. "#{{Collectible263}} + {{Collectible356}} " .. synergy
	end

	return descObj
end

EID:addDescriptionModifier("SoulEdithClearRuneCarBattery", SoulEdithCondition, SoulEdithCallback)

--Lithium Pill
local Lithium = {
	IFRAME_INCREASE_AMOUNT = 20,
	FALSEPHD_IFRAME_INCREASE_AMOUNT = 5,
}

local lithiumEN = "#{{ArrowDown}} Decreases one random stat#{{ArrowUp}} IFRAME_INCREASE_AMOUNT invincibility frames"
local lithiumRU =
	"#{{ArrowDown}} Уменьшает случайную характеристику#{{ArrowUp}} IFRAME_INCREASE_AMOUNT кадров неуязвимости"

EID:addPill(EdithRestored.Enums.Pickups.PillEffects.PILLEFFECT_LITHIUM, lithiumEN, "Lithium")
EID:addPill(EdithRestored.Enums.Pickups.PillEffects.PILLEFFECT_LITHIUM, lithiumRU, "Литий", "ru")
EID:addHorsePill(EdithRestored.Enums.Pickups.PillEffects.PILLEFFECT_LITHIUM, lithiumEN, "Lithium")
EID:addHorsePill(EdithRestored.Enums.Pickups.PillEffects.PILLEFFECT_LITHIUM, lithiumRU, "Литий", "ru")

local function LithiumCondition(descObj)
	if
		descObj.ObjType == 5
		and descObj.ObjVariant == 70
		and descObj.ObjSubType % 2048 == EdithRestored.Enums.Pickups.Pills.PILL_LITHIUM
		and (descObj and descObj.Entity or HodlingTab())
	then
		return true
	end
	return false
end

local function LithiumCallback(descObj)
	local player = game:GetNearestPlayer(descObj.Entity.Position)

	local horseMul = descObj.ObjSubType > 2048 and 2 or 1
	if
		player:HasCollectible(CollectibleType.COLLECTIBLE_PHD)
		and not player:HasCollectible(CollectibleType.COLLECTIBLE_FALSE_PHD)
	then
		descObj.Description = descObj.Description:gsub(".*%#", "")
		descObj.Description =
			descObj.Description:gsub("IFRAME_INCREASE_AMOUNT", "+" .. (Lithium.IFRAME_INCREASE_AMOUNT * horseMul))
	else
		local extra = nil
		for idx, _ in pairs(Lithium) do
			if idx:sub(1, 9) ~= "FALSEPHD_" then
				if player:HasCollectible(CollectibleType.COLLECTIBLE_FALSE_PHD) then
					if type(extra) == "nil" then
						extra = descObj.Description
					end
					local amount = Lithium["FALSEPHD_" .. idx] * horseMul
					extra = extra:gsub(idx, amount > 0 and "+" .. amount or amount)
				end
				local amount = Lithium[idx] * horseMul
				descObj.Description = descObj.Description:gsub(idx, amount > 0 and "+" .. amount or amount)
			end
		end
		if type(extra) ~= "nil" then
			descObj.Description = descObj.Description .. extra:gsub("#", "#{{Collectible654}} {{Blank}}")
		end
	end

	return descObj
end

EID:addDescriptionModifier("LithiumPHDFalsePHD", LithiumCondition, LithiumCallback)

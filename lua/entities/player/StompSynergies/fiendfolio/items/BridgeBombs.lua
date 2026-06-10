local BridgeBombs = {}
local sfx = EdithRestored.SFX

-- https://www.geeksforgeeks.org/check-if-any-point-overlaps-the-given-circle-and-rectangle/
local function gridInRadius(grid, pos, radius)
	local x1 = grid.Position.X - 20
	local x2 = grid.Position.X + 20
	local y1 = grid.Position.Y - 20
	local y2 = grid.Position.Y + 20
	
    local xn = math.max(x1, math.min(pos.X, x2))
    local yn = math.max(y1, math.min(pos.Y, y2))
	
    local dx = xn - pos.X
    local dy = yn - pos.Y
	
    return (dx ^ 2 + dy ^ 2) <= radius ^ 2
end

---@param player EntityPlayer
---@param bombDamage number
---@param position Vector
---@param radius number
---@param hasBombs boolean
---@param isGigaBomb boolean
---@param isScatterBomb boolean
---@return table?
function BridgeBombs:OnStompExplosion(player, bombDamage, position, radius, hasBombs, isGigaBomb, isScatterBomb)
	if not (EdithRestored.Room():GetType() == RoomType.ROOM_BOSS and EdithRestored.Room():GetBossID() == 55) then
		local madeBridge = false
		for x = math.ceil(radius / 40) * -1, math.ceil(radius / 40) do
			for y = math.ceil(radius / 40) * -1, math.ceil(radius / 40) do
				local grid = room:GetGridEntityFromPos(Vector(position.X + 40 * x, position.Y + 40 * y))
				if grid and grid:ToPit() then
					local pit = grid:ToPit()
					if gridInRadius(pit, position, radius) then
						pit:MakeBridge(nil)
						madeBridge = true
					end
				end
			end
		end

		if madeBridge then
			sfx:Play(SoundEffect.SOUND_ROCK_CRUMBLE, 1.0, 0, false, 1.0)
		end
	end
end
EdithRestored:AddCallback(
	EdithRestored.Enums.Callbacks.ON_EDITH_STOMP_EXPLOSION,
	BridgeBombs.OnStompExplosion,
	{ Item = FiendFolio.ITEM.COLLECTIBLE.BRIDGE_BOMBS, PoolScatterBombs = true }
)

return BridgeBombs

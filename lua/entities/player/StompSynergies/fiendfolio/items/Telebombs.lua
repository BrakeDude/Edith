local Telebombs = {}
local sfx = EdithRestored.SFX

---@param player EntityPlayer
---@param bombDamage number
---@param position Vector
---@param radius number
---@param hasBombs boolean
---@param isGigaBomb boolean
---@param isScatterBomb boolean
---@return table?
function Telebombs:OnStompExplosion(player, bombDamage, position, radius, hasBombs, isGigaBomb, isScatterBomb)
	if not isScatterBomb then
		Isaac.CreateTimer(function()
			local data = player:GetData()
			if data.telebombMarker and data.telebombMarker:GetData().isActive then
				player.Position = data.telebombMarker.Position
				player:SetColor(Color(1,1,1,1,1,1,1),3,1,true,false)
				sfx:Play(SoundEffect.SOUND_HELL_PORTAL1,1,0,false,1)
				data.telebombMarker:Remove()
				data.telebombMarker = nil

				for _, entity in pairs(Isaac.FindInRadius(player.Position, 40, EntityPartition.ENEMY)) do
					if not FiendFolio:isFriend(entity) then
						entity:TakeDamage(20, 0, EntityRef(player), 0)
					end
				end
			end
		end, 1, 1, false)
	end
end
EdithRestored:AddPriorityCallback(
	EdithRestored.Enums.Callbacks.ON_EDITH_STOMP_EXPLOSION,
	CallbackPriority.LATE + 200,
	Telebombs.OnStompExplosion,
	{Item = FiendFolio.ITEM.COLLECTIBLE.TELEBOMBS }
)

return Telebombs

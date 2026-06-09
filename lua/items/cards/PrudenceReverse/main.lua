local Cards = {}
local Helpers = EdithRestored.Helpers

function Cards:UseReversePrudence(_, player)
    local slot = TSIL.EntitySpecific.SpawnSlot(
        SlotVariant.CRANE_GAME,
        0,
        EdithRestored.Room():FindFreePickupSpawnPosition(player.Position, 40, true)
    )
    TSIL.EntitySpecific.SpawnEffect(EffectVariant.POOF01, 0, slot.Position)

    Helpers.PlaySND(EdithRestored.Enums.SFX.Cards.CARD_REVERSE_PRUDENCE)
    SFXManager():Play(SoundEffect.SOUND_SUMMONSOUND, 1, 0)
end
EdithRestored:AddCallback(ModCallbacks.MC_USE_CARD, Cards.UseReversePrudence, EdithRestored.Enums.Pickups.Cards.CARD_REVERSE_PRUDENCE)
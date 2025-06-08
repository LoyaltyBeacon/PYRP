-- Faction system client script
function inviteToFaction(id)
    triggerServerEvent('factionSystem:invitePlayer', localPlayer, id, localPlayer)
end

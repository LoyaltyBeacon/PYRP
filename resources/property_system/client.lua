-- Client helpers for the property system

addCommandHandler('lock', function(_, id)
    if id then
        triggerServerEvent('propertySystem:toggleLock', localPlayer, tonumber(id))
    end
end)

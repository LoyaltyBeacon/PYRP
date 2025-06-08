-- Project Y RP - Core client script

function requestPlayerData()
    triggerServerEvent('pyrp:loadPlayerData', localPlayer)
end

function savePlayer()
    triggerServerEvent('pyrp:savePlayerData', localPlayer)
end

addEventHandler('onClientResourceStart', resourceRoot, requestPlayerData)
addEventHandler('onClientResourceStop', resourceRoot, savePlayer)

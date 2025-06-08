-- Client-side helpers for the police system

addEvent('police:notifyJailTime', true)
addEventHandler('police:notifyJailTime', localPlayer, function(minutes)
    outputChatBox('You have been jailed for '..tostring(minutes)..' minutes.')
end)

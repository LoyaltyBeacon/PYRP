-- GPS server logic
function sendWaypoint(player, x, y, z)
    triggerClientEvent(player, 'gps:setWaypoint', resourceRoot, x, y, z)
end
addEvent('gps:sendWaypoint', true)
addEventHandler('gps:sendWaypoint', root, sendWaypoint)

-- GPS client script
function setWaypoint(x, y, z)
    setWaypoint(x, y)
end
addEvent('gps:setWaypoint', true)
addEventHandler('gps:setWaypoint', root, setWaypoint)

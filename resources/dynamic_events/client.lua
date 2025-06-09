-- Client notifications for dynamic RP events

local incident

addEvent('dynamicEvents:notify', true)
addEventHandler('dynamicEvents:notify', root, function(data)
    incident = data
    addEventHandler('onClientRender', root, drawIncident)
end)

local function clearIncident()
    removeEventHandler('onClientRender', root, drawIncident)
    incident = nil
end

function drawIncident()
    if not incident then return end
    dxDrawRectangle(20, 100, 300, 100, tocolor(30,30,30,200))
    dxDrawText('RP INCIDENT', 30,110,0,0,tocolor(255,0,0),1,'default-bold')
    dxDrawText(incident.typ..'\n'..incident.desc,30,130,0,0,tocolor(255,255,255),1,'default')
    dxDrawRectangle(30,180,120,25,tocolor(0,150,255))
    dxDrawText('Navigovať',40,185,0,0,tocolor(255,255,255),1,'default-bold')
end

addEventHandler('onClientClick', root, function(btn,state,x,y)
    if btn=='left' and state=='down' and incident then
        if x>=30 and x<=150 and y>=180 and y<=205 then
            triggerServerEvent('assignBlipAndRoute', resourceRoot, incident)
            clearIncident()
        end
    end
end)

addEvent('dynamicEvents:clear', true)
addEventHandler('dynamicEvents:clear', root, clearIncident)

-- Dynamic RP Events system

local db
local F = {}
local incidents = {
    {
        typ = 'Bezvedomie na ulici',
        desc = 'Osoba v bezvedomí leží na chodníku.',
        factions = {EMS=1},
        pos = {x=1175.35, y=-1323.2, z=14.1}
    },
    {
        typ = 'Požiar vozidla',
        desc = 'Horiace auto pri benzínke.',
        factions = {HASIC=1},
        pos = {x=1940.7, y=-1761.2, z=13.5}
    },
    {
        typ = 'Dopravná nehoda',
        desc = 'Zrážka dvoch áut, podozrenie na zranenia.',
        factions = {EMS=1, PD=1},
        pos = {x=1465.8, y=-1014.4, z=23.8}
    }
}

local lastEvent = 0
local cooldown = 600000 -- 10 minutes

local function getFactionCount(name)
    local count = 0
    for _,p in ipairs(getElementsByType('player')) do
        if getElementData(p,'faction') == name and getElementData(p,'duty') then
            count = count + 1
        end
    end
    return count
end

local function chooseIncident()
    local available = {}
    local ems = getFactionCount(F.EMS)
    local pd = getFactionCount(F.PD)
    local fd = getFactionCount(F.HASIC)
    for _,inc in ipairs(incidents) do
        local ok = true
        if inc.factions.EMS and ems < inc.factions.EMS then ok=false end
        if inc.factions.PD and pd < inc.factions.PD then ok=false end
        if inc.factions.HASIC and fd < inc.factions.HASIC then ok=false end
        if ok then table.insert(available, inc) end
    end
    if #available == 0 then return nil end
    return available[math.random(#available)]
end

local function logEvent(typ, location)
    if not db then return end
    dbExec(db, 'INSERT INTO events_log (typ,lokacia,stav,spustene) VALUES (?,?,\'active\',NOW())', typ, location)
end

local activeMarker

local function triggerIncident(force)
    if not force and getTickCount() - lastEvent < cooldown then return end
    local inc = chooseIncident()
    if not inc then return end
    lastEvent = getTickCount()
    logEvent(inc.typ, inc.pos.x..','..inc.pos.y)
    if activeMarker then destroyElement(activeMarker) activeMarker=nil end
    activeMarker = createMarker(inc.pos.x, inc.pos.y, inc.pos.z, 'checkpoint', 2, 255,0,0)
    dispatchToFaction(F.EMS, inc)
    dispatchToFaction(F.PD, inc)
    dispatchToFaction(F.HASIC, inc)
end

function dispatchToFaction(faction, data)
    for _,p in ipairs(getElementsByType('player')) do
        if getElementData(p,'faction') == faction and getElementData(p,'duty') then
            triggerClientEvent(p,'dynamicEvents:notify', resourceRoot, data)
        end
    end
end

addEvent('dynamicEvents:request', true)
addEventHandler('dynamicEvents:request', root, function()
    triggerIncident(true)
end)

addEventHandler('onResourceStart', resourceRoot, function()
    db = exports.pyrp_core:getDB()
    if exports.faction_system then
        F = exports.faction_system:getBaseFactionNames() or exports.faction_system:getBaseFactionIds()
    end
    if db then
        dbExec(db, [[CREATE TABLE IF NOT EXISTS events_log (
            id INT AUTO_INCREMENT PRIMARY KEY,
            typ VARCHAR(50),
            lokacia VARCHAR(100),
            stav VARCHAR(20),
            spustene TIMESTAMP,
            vyriesene TIMESTAMP NULL,
            zucastneni TEXT
        )]])
    end
    setTimer(triggerIncident, 300000, 0) -- every 5 minutes check
end)


addEvent('assignBlipAndRoute', true)
addEventHandler('assignBlipAndRoute', resourceRoot, function(data)
    local blip = createBlip(data.pos.x, data.pos.y, data.pos.z, 41, 2, 255,0,0)
    setElementData(client, 'incidentBlip', blip)
end)

addEventHandler('onMarkerHit', resourceRoot, function(plr)
    if source == activeMarker and getElementType(plr) == 'player' then
        destroyElement(activeMarker)
        activeMarker = nil
        local blip = getElementData(plr,'incidentBlip')
        if blip then destroyElement(blip) end
        triggerClientEvent(plr,'dynamicEvents:clear', resourceRoot)
    end
end)


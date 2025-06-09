-- Faction system server logic
local factions = {}
local nameToId = {}
local BASE_FACTIONS = {}
local BASE_NAMES = {VLADA='VLADA', EMS='EMS', PD='PD', HASIC='HASIC'}

function createFaction(name)
    if nameToId[name] then
        return nameToId[name]
    end
    local id = #factions + 1
    factions[id] = {name = name, members = {}}
    nameToId[name] = id
    return id
end

function invitePlayerToFaction(factionId, player)
    if not factions[factionId] then return end
    factions[factionId].members[player] = true
    outputChatBox('You joined faction '..factions[factionId].name, player)
end
addEvent('factionSystem:invitePlayer', true)
addEventHandler('factionSystem:invitePlayer', root, invitePlayerToFaction)

function getFactionStats()
    local list = {}
    for id,data in pairs(factions) do
        local count = 0
        for _ in pairs(data.members) do count = count + 1 end
        table.insert(list, {id=id, name=data.name, members=count})
    end
    table.sort(list, function(a,b) return a.members > b.members end)
    return list
end
exports('getFactionStats', getFactionStats)

function getFactionId(name)
    return nameToId[name]
end

function getFactionName(id)
    return factions[id] and factions[id].name
end

function getBaseFactionIds()
    return BASE_FACTIONS
end

function getBaseFactionNames()
    return BASE_NAMES
end

exports('getFactionId', getFactionId)
exports('getFactionName', getFactionName)
exports('getBaseFactionIds', getBaseFactionIds)
exports('getBaseFactionNames', getBaseFactionNames)

addEventHandler('onResourceStart', resourceRoot, function()
    for key,name in pairs(BASE_NAMES) do
        BASE_FACTIONS[key] = createFaction(name)
    end
end)

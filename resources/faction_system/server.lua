-- Faction system server logic
local factions = {}

function createFaction(name)
    local id = #factions + 1
    factions[id] = {name = name, members = {}}
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

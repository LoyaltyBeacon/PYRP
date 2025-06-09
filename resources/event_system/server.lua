-- RP Event management system

local db
local events = {}
local participants = {}

local function loadEvents()
    if not db then return end
    events = {}
    participants = {}
    local q = dbQuery(db, 'SELECT * FROM rp_events ORDER BY datetime')
    local res = dbPoll(q, -1)
    for _,row in ipairs(res or {}) do
        events[row.id] = row
    end
    q = dbQuery(db, 'SELECT * FROM event_participants')
    res = dbPoll(q, -1)
    for _,row in ipairs(res or {}) do
        participants[row.event_id] = participants[row.event_id] or {}
        table.insert(participants[row.event_id], row.player_id)
    end
end

addEventHandler('onResourceStart', resourceRoot, function()
    db = exports.pyrp_core:getDB()
    if not db then return end
    dbExec(db, [[CREATE TABLE IF NOT EXISTS rp_events (
        id INT AUTO_INCREMENT PRIMARY KEY,
        title VARCHAR(100),
        description TEXT,
        datetime DATETIME,
        location VARCHAR(100),
        created_by INT
    )]])
    dbExec(db, [[CREATE TABLE IF NOT EXISTS event_participants (
        id INT AUTO_INCREMENT PRIMARY KEY,
        player_id INT,
        event_id INT
    )]])
    loadEvents()
end)

local function getCharID(plr)
    return getElementData(plr, 'character:id') or getElementData(plr, 'account:id')

end
function createEvent(player, title, desc, time, location)
    if not db then return false end
    local creator = getCharID(player)
    if not creator then return false end
    local q = dbQuery(db, 'INSERT INTO rp_events (title,description,datetime,location,created_by) VALUES (?,?,?,?,?)', title, desc, time, location or '', creator)
    local res, num, id = dbPoll(q, -1)
    if id then
        events[id] = {id=id,title=title,description=desc,datetime=time,location=location,created_by=creator}
        outputChatBox('Event #'..id..' created.', player)
        return id
    end
    return false
end

function editEvent(player, id, newData)
    id = tonumber(id)
    local ev = events[id]
    if not ev or not db then return end
    for k,v in pairs(newData) do
        ev[k] = v
    end
    dbExec(db, 'UPDATE rp_events SET title=?, description=?, datetime=?, location=? WHERE id=?', ev.title, ev.description, ev.datetime, ev.location, id)
    outputChatBox('Event #'..id..' updated.', player)
end

function deleteEvent(player, id)
    id = tonumber(id)
    if not events[id] or not db then return end
    events[id] = nil
    participants[id] = nil
    dbExec(db, 'DELETE FROM rp_events WHERE id=?', id)
    dbExec(db, 'DELETE FROM event_participants WHERE event_id=?', id)
end
    outputChatBox('Event #'..id..' deleted.', player)

function registerToEvent(player, eventID)
    eventID = tonumber(eventID)
    if not events[eventID] or not db then return end
    local pid = getCharID(player)
    if not pid then return end
    participants[eventID] = participants[eventID] or {}
    for _,p in ipairs(participants[eventID]) do
        if p == pid then
            outputChatBox('Už si prihlásený na tento event.', player)
            return
        end
    end
    table.insert(participants[eventID], pid)
    dbExec(db, 'INSERT INTO event_participants (player_id,event_id) VALUES (?,?)', pid, eventID)
    outputChatBox('Prihlásený na event #'..eventID, player)
end

function unregisterFromEvent(player, eventID)
    eventID = tonumber(eventID)
    if not participants[eventID] or not db then return end
    local pid = getCharID(player)
    if not pid then return end
    for i,p in ipairs(participants[eventID]) do
        if p == pid then
            table.remove(participants[eventID], i)
            dbExec(db, 'DELETE FROM event_participants WHERE event_id=? AND player_id=?', eventID, pid)
            outputChatBox('Odhlásený z eventu #'..eventID, player)
            return
        end
    end
end

function getEventList()
    local list = {}
    for _,ev in pairs(events) do table.insert(list, ev) end
    table.sort(list, function(a,b) return a.datetime < b.datetime end)
    return list
end

function getEventParticipants(eventID)
    return participants[eventID] or {}
end

addEvent("events:requestList", true)
addEventHandler("events:requestList", root, function()
    triggerClientEvent(client or source, "events:receiveList", resourceRoot, getEventList())
end)


-- commands
addCommandHandler('vytvorevent', function(plr, cmd, ...)
    local args = {...}
    local title = table.remove(args,1)
    local time = table.remove(args,1)
    local desc = table.concat(args, ' ')
    if title and time then
        createEvent(plr, title, desc, time)
    end
end)

addCommandHandler('eventprihlas', function(plr, cmd, id)
    registerToEvent(plr, id)
end)

addCommandHandler('zrusitprihlasenie', function(plr, cmd, id)
    unregisterFromEvent(plr, id)
end)

addCommandHandler('mojeudalosti', function(plr)
    local pid = getCharID(plr)
    if not pid then return end
    for id,list in pairs(participants) do
        for _,p in ipairs(list) do
            if p == pid then
                local ev = events[id]
                if ev then
                    outputChatBox('#'..id..' '..ev.title..' '..ev.datetime, plr)
                end
            end
        end
    end
end)

addCommandHandler('eventy', function(plr)
    for _,ev in ipairs(getEventList()) do
        outputChatBox('#'..ev.id..' '..ev.title..' '..ev.datetime, plr)
    end
end)

exports('createEvent', createEvent)
exports('editEvent', editEvent)
exports('deleteEvent', deleteEvent)
exports('registerToEvent', registerToEvent)
exports('getEventList', getEventList)
exports('getEventParticipants', getEventParticipants)

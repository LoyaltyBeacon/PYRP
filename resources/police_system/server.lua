-- Police, jail and crime system for Project Y RP

local db

addEventHandler('onResourceStart', resourceRoot, function()
    db = exports.pyrp_core:getDB()
    if not db then return end
    dbExec(db, [[CREATE TABLE IF NOT EXISTS criminal_records (
        id INT AUTO_INCREMENT PRIMARY KEY,
        player_id INT,
        crime_type VARCHAR(50),
        severity VARCHAR(20),
        officer_id INT,
        timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        resolved BOOLEAN DEFAULT 0
    )]])
    dbExec(db, [[CREATE TABLE IF NOT EXISTS wanted_levels (
        player_id INT PRIMARY KEY,
        level INT,
        reason TEXT,
        timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )]])
    dbExec(db, [[CREATE TABLE IF NOT EXISTS jail_log (
        id INT AUTO_INCREMENT PRIMARY KEY,
        player_id INT,
        officer_id INT,
        reason TEXT,
        time INT,
        released_at TIMESTAMP NULL
    )]])
end)

local jailTimers = {}

local function recordCrime(player, crime, severity, officer)
    if not db then return end
    local pid = getElementData(player, 'character:id')
    if not pid then return end
    local oid = officer and getElementData(officer,'character:id') or nil
    dbExec(db, 'INSERT INTO criminal_records (player_id,crime_type,severity,officer_id) VALUES (?,?,?,?)', pid, crime, severity, oid)
end

function setWantedLevel(player, level, reason)
    if not db then return end
    local pid = getElementData(player,'character:id')
    if not pid then return end
    dbExec(db, 'REPLACE INTO wanted_levels (player_id,level,reason) VALUES (?,?,?)', pid, level, reason or '')
    setElementData(player, 'police:wanted', level)
end
exports('setWantedLevel', setWantedLevel)

function viewCriminalRecord(player, target)
    if not db then return end
    local tid = getElementData(target,'character:id')
    if not tid then return end
    local q = dbQuery(db, 'SELECT crime_type,severity,timestamp FROM criminal_records WHERE player_id=?', tid)
    local res = dbPoll(q, -1)
    outputChatBox('--- Criminal Record ---', player)
    for _,row in ipairs(res or {}) do
        outputChatBox(string.format('%s (%s) on %s', row.crime_type, row.severity, row.timestamp), player)
    end
end
exports('viewCriminalRecord', viewCriminalRecord)

function issueWarrant(player, reason, officer)
    recordCrime(player, 'warrant', reason, officer)
    setWantedLevel(player, 3, reason)
end
exports('issueWarrant', issueWarrant)

function arrestPlayer(police, suspect)
    toggleControl(suspect, 'fire', false)
    toggleControl(suspect, 'jump', false)
    setElementFrozen(suspect, true)
end
exports('arrestPlayer', arrestPlayer)

local function release(player)
    if isTimer(jailTimers[player]) then killTimer(jailTimers[player]) end
    setElementFrozen(player, false)
    toggleControl(player, 'fire', true)
    toggleControl(player, 'jump', true)
    setElementInterior(player, 0)
    setElementPosition(player, 1600, -1600, 13)
    local pid = getElementData(player,'character:id')
    if pid and db then
        dbExec(db, 'UPDATE jail_log SET released_at=NOW() WHERE player_id=? AND released_at IS NULL', pid)
    end
end

function jailPlayer(player, minutes, reason, officer)
    minutes = tonumber(minutes) or 1
    local pid = getElementData(player,'character:id')
    if pid and db then
        local oid = officer and getElementData(officer,'character:id') or nil
        dbExec(db, 'INSERT INTO jail_log (player_id,officer_id,reason,time) VALUES (?,?,?,?)', pid, oid, reason or '', minutes)
    end
    setElementPosition(player, 264.6, 77.5, 1001)
    setElementInterior(player, 6)
    triggerClientEvent(player, 'police:notifyJailTime', player, minutes)
    jailTimers[player] = setTimer(function()
        release(player)
    end, minutes * 60000, 1)
end
exports('jailPlayer', jailPlayer)

function releasePlayer(player)
    release(player)
end
exports('releasePlayer', releasePlayer)

addCommandHandler('vezni', function(police, cmd, targetName, mins)
    local t = getPlayerFromName(targetName)
    if not t then return end
    jailPlayer(t, tonumber(mins) or 5, 'Police jail', police)
end)

addCommandHandler('hladany', function(p)
    local pid = getElementData(p,'character:id')
    if not pid then return end
    local q = dbQuery(db, 'SELECT player_id,level,reason FROM wanted_levels')
    local res = dbPoll(q,-1)
    for _,r in ipairs(res or {}) do
        outputChatBox(string.format('ID:%s Wanted:%d Reason:%s', r.player_id, r.level, r.reason), p)
    end
end)


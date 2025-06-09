-- Admin panel and control system
local admins = {}
local db

local roles = {Support=1, Moderator=2, Admin=3, HeadAdmin=4}

function setAdmin(player, level)
    admins[player] = tonumber(level) or 0
end
addEvent('admin:setAdmin', true)
addEventHandler('admin:setAdmin', root, setAdmin)

function isAdmin(player, level)
    return (admins[player] or 0) >= (level or 1)
end

local function getAccID(p)
    return getElementData(p, 'account:id') or 0
end

local function logAction(admin, target, action, reason)
    if not db then return end
    local aid = getAccID(admin)
    local tid = target and getAccID(target) or 0
    dbExec(db, 'INSERT INTO admin_actions (admin_id,target_id,action,reason) VALUES (?,?,?,?)', aid, tid, action, reason or '')
end

addEventHandler('onResourceStart', resourceRoot, function()
    db = exports.pyrp_core:getDB()
    if not db then return end
    dbExec(db, [[CREATE TABLE IF NOT EXISTS admin_actions (
        id INT AUTO_INCREMENT PRIMARY KEY,
        admin_id INT,
        target_id INT,
        action VARCHAR(32),
        reason TEXT,
        timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )]])
    dbExec(db, [[CREATE TABLE IF NOT EXISTS reports (
        id INT AUTO_INCREMENT PRIMARY KEY,
        reporter_id INT,
        reported_id INT,
        message TEXT,
        status VARCHAR(16) DEFAULT 'open',
        response TEXT,
        timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )]])
end)

-- admin chat
addCommandHandler('a', function(p, cmd, ...)
    if not isAdmin(p, 1) then return end
    local msg = table.concat({...}, ' ')
    if msg == '' then return end
    for plr,l in pairs(admins) do
        if l > 0 then
            outputChatBox('[AdminChat] '..getPlayerName(p)..': '..msg, plr, 255,100,100)
        end
    end
end)

-- report command
addCommandHandler('report', function(p, cmd, targetName, ...)
    local text = table.concat({...}, ' ')
    if not targetName or text == '' then return end
    local target = getPlayerFromName(targetName)
    local rid = getAccID(p)
    local tid = target and getAccID(target) or 0
    if db then
        dbExec(db, 'INSERT INTO reports (reporter_id,reported_id,message) VALUES (?,?,?)', rid, tid, text)
    end
    for plr,l in pairs(admins) do
        if l > 0 then
            outputChatBox('[Report] '..getPlayerName(p)..' on '..(target and getPlayerName(target) or targetName)..': '..text, plr, 255,200,0)
        end
    end
end)

-- basic commands
addCommandHandler('kick', function(p, cmd, targetName, ...)
    if not isAdmin(p, roles.Support) then return end
    local target = getPlayerFromName(targetName or '')
    if target then
        local reason = table.concat({...}, ' ')
        kickPlayer(target, p, reason)
        logAction(p, target, 'kick', reason)
    end
end)

addCommandHandler('ban', function(p, cmd, targetName, ...)
    if not isAdmin(p, roles.Moderator) then return end
    local target = getPlayerFromName(targetName or '')
    if target then
        local reason = table.concat({...}, ' ')
        banPlayer(target, true, false, p, reason, 0)
        logAction(p, target, 'ban', reason)
    end
end)

addCommandHandler('freeze', function(p, cmd, targetName)
    if not isAdmin(p, roles.Support) then return end
    local target = getPlayerFromName(targetName or '')
    if target then
        setElementFrozen(target, true)
        logAction(p, target, 'freeze')
    end
end)

addCommandHandler('unfreeze', function(p, cmd, targetName)
    if not isAdmin(p, roles.Support) then return end
    local target = getPlayerFromName(targetName or '')
    if target then
        setElementFrozen(target, false)
        logAction(p, target, 'unfreeze')
    end
end)

addCommandHandler('mute', function(p, cmd, targetName, minutes)
    if not isAdmin(p, roles.Support) then return end
    local target = getPlayerFromName(targetName or '')
    if target then
        setPlayerMuted(target, true)
        logAction(p, target, 'mute', minutes)
    end
end)

addCommandHandler('unmute', function(p, cmd, targetName)
    if not isAdmin(p, roles.Support) then return end
    local target = getPlayerFromName(targetName or '')
    if target then
        setPlayerMuted(target, false)
        logAction(p, target, 'unmute')
    end
end)

addCommandHandler('goto', function(p, cmd, targetName)
    if not isAdmin(p, roles.Support) then return end
    local target = getPlayerFromName(targetName or '')
    if target then
        local x,y,z = getElementPosition(target)
        setElementPosition(p, x+1, y, z)
    end
end)

addCommandHandler('gethere', function(p, cmd, targetName)
    if not isAdmin(p, roles.Support) then return end
    local target = getPlayerFromName(targetName or '')
    if target then
        local x,y,z = getElementPosition(p)
        setElementPosition(target, x+1, y, z)
        logAction(p, target, 'gethere')
    end
end)

addCommandHandler('getinfo', function(p, cmd, targetName)
    if not isAdmin(p, roles.Support) then return end
    local target = getPlayerFromName(targetName or '')
    if target then
        outputChatBox('Nick: '..getPlayerName(target)..' | IP: '..getPlayerIP(target), p)
    end
end)

-- export for other resources
exports('isAdmin', isAdmin)

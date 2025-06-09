-- Advanced health system for Project Y RP

local db

local function init()
    db = exports.pyrp_core:getDB()
    if not db then return end
    dbExec(db, [[CREATE TABLE IF NOT EXISTS health_status (
        player_id INT PRIMARY KEY,
        health INT DEFAULT 100,
        injured BOOLEAN DEFAULT 0,
        injury_type VARCHAR(50),
        bleeding BOOLEAN DEFAULT 0,
        unconscious BOOLEAN DEFAULT 0,
        last_healed TIMESTAMP
    )]])
end
addEventHandler('onResourceStart', resourceRoot, init)

local function loadHealth(player, accID)
    if not db then return end
    local q = dbQuery(db, 'SELECT * FROM health_status WHERE player_id=?', accID)
    local r = dbPoll(q, -1)
    if r and r[1] then
        local row = r[1]
        setElementHealth(player, row.health)
        setElementData(player, 'health:injured', row.injured)
        setElementData(player, 'health:type', row.injury_type or '')
        setElementData(player, 'health:bleeding', row.bleeding)
        setElementData(player, 'health:unconscious', row.unconscious)
    else
        dbExec(db, 'INSERT INTO health_status (player_id) VALUES (?)', accID)
        setElementHealth(player, 100)
        setElementData(player, 'health:injured', 0)
        setElementData(player, 'health:type', '')
        setElementData(player, 'health:bleeding', 0)
        setElementData(player, 'health:unconscious', 0)
    end
end
addEvent('account:postLogin', true)
addEventHandler('account:postLogin', root, loadHealth)

local function saveHealth(player)
    if not db then return end
    local accID = getElementData(player, 'account:id')
    if not accID then return end
    dbExec(db, 'REPLACE INTO health_status (player_id,health,injured,injury_type,bleeding,unconscious,last_healed) VALUES (?,?,?,?,?,?,NOW())',
        accID,
        math.floor(getElementHealth(player)),
        getElementData(player, 'health:injured') or 0,
        getElementData(player, 'health:type') or '',
        getElementData(player, 'health:bleeding') or 0,
        getElementData(player, 'health:unconscious') or 0
    )
end
addEventHandler('onPlayerQuit', root, saveHealth)
addEventHandler('onResourceStop', resourceRoot, function()
    for _,p in ipairs(getElementsByType('player')) do
        saveHealth(p)
    end
end)

local injuryMap = {
    [4]='gunshot', -- weapon 4: Colt45 etc
    [5]='gunshot', [6]='gunshot',
    [50]='burn'
}

addEventHandler('onPlayerDamage', root, function(attacker, weapon, bodypart)
    local hp = getElementHealth(source)
    if hp <= 0 then return end
    local typ = injuryMap[weapon] or 'injury'
    setElementData(source, 'health:injured', 1)
    setElementData(source, 'health:type', typ)
    if hp < 20 then
        setElementData(source, 'health:unconscious', 1)
    end
end)

local function healPlayer(player)
    setElementHealth(player, 100)
    setElementData(player, 'health:injured', 0)
    setElementData(player, 'health:type', '')
    setElementData(player, 'health:bleeding', 0)
    setElementData(player, 'health:unconscious', 0)
    triggerClientEvent(player, 'healthSystem:onHealed', resourceRoot)
    saveHealth(player)
end

addCommandHandler('vyliecit', function(p, cmd, targetName)
    if not targetName then return end
    local target = getPlayerFromName(targetName)
    if not target then return end
    healPlayer(target)
    outputChatBox('Player healed.', p)
end)

addCommandHandler('volajzachranku', function(p)
    local x,y,z = getElementPosition(p)
    for _,pl in ipairs(getElementsByType('player')) do
        outputChatBox(p:getName()..' potrebuje pomoc! ( /diagnoza '..p:getName()..' )', pl)
    end
end)

addCommandHandler('diagnoza', function(p, cmd, targetName)
    if not targetName then return end
    local target = getPlayerFromName(targetName)
    if not target then return end
    local typ = getElementData(target, 'health:type') or 'none'
    local inj = getElementData(target, 'health:injured') == 1 and 'Yes' or 'No'
    outputChatBox('Injured: '..inj..' Type: '..typ, p)
end)

addCommandHandler('mojzdravotnyzaznam', function(p)
    local hp = getElementHealth(p)
    local inj = getElementData(p,'health:injured')==1 and 'Yes' or 'No'
    local typ = getElementData(p,'health:type') or 'none'
    outputChatBox(string.format('HP: %d | Injured: %s | Type: %s', hp, inj, typ), p)
end)

addCommandHandler('odpadnut', function(p)
    setElementData(p,'health:unconscious',1)
    setPedAnimation(p,'CRACK','crckidle3')
    setTimer(function()
        setPedAnimation(p)
        setElementData(p,'health:unconscious',0)
    end, 10000, 1)
end)

exports('healPlayer', healPlayer)

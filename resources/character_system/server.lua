-- Character system server logic with MySQL storage
local db

addEventHandler('onResourceStart', resourceRoot, function()
    db = exports.pyrp_core:getDB()
    if db then
        dbExec(db, [[CREATE TABLE IF NOT EXISTS characters (
            id INT AUTO_INCREMENT PRIMARY KEY,
            account_id INT,
            name VARCHAR(32),
            gender VARCHAR(10),
            posX FLOAT, posY FLOAT, posZ FLOAT
        )]])
    end
end)

local function sendList(player)
    if not db then return end
    local accID = getElementData(player, 'account:id')
    if not accID then return end
    local q = dbQuery(db, 'SELECT * FROM characters WHERE account_id=?', accID)
    local result = dbPoll(q, -1)
    triggerClientEvent(player, 'characterSystem:receiveList', resourceRoot, result or {})
end
addEvent('characterSystem:getList', true)
addEventHandler('characterSystem:getList', root, sendList)

local function createCharacter(player, name, gender)
    if not db then return end
    local accID = getElementData(player, 'account:id')
    if not accID then return end
    dbExec(db, 'INSERT INTO characters (account_id,name,gender,posX,posY,posZ) VALUES (?,?,?,?,?,?)',
        accID, name, gender, 0, 0, 3)
    sendList(player)
end
addEvent('characterSystem:create', true)
addEventHandler('characterSystem:create', root, createCharacter)

local function selectCharacter(player, id)
    if not db then return end
    local accID = getElementData(player, 'account:id')
    if not accID then return end
    local q = dbQuery(db, 'SELECT * FROM characters WHERE id=? AND account_id=?', id, accID)
    local res = dbPoll(q, -1)
    if res and res[1] then
        local c = res[1]
        spawnPlayer(player, c.posX, c.posY, c.posZ)
        setPlayerName(player, c.name)
        setElementData(player, 'character:id', c.id)
    end
end
addEvent('characterSystem:select', true)
addEventHandler('characterSystem:select', root, selectCharacter)

addEventHandler('onPlayerQuit', root, function()
    if not db then return end
    local charId = getElementData(source, 'character:id')
    if charId then
        local x, y, z = getElementPosition(source)
        dbExec(db, 'UPDATE characters SET posX=?, posY=?, posZ=? WHERE id=?', x, y, z, charId)
    end
end)

addEventHandler('onResourceStop', resourceRoot, function()
    for _, player in ipairs(getElementsByType('player')) do
        local charId = getElementData(player, 'character:id')
        if charId then
            local x, y, z = getElementPosition(player)
            dbExec(db, 'UPDATE characters SET posX=?, posY=?, posZ=? WHERE id=?', x, y, z, charId)
        end
    end
end)

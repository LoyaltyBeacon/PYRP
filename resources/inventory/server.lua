-- Inventory system server logic for Project Y RP
-- Provides weight-based inventories with persistence in MySQL

local db
local inventories = {}
local items = {}

local function loadItemDefinitions()
    if not db then return end
    dbExec(db, [[CREATE TABLE IF NOT EXISTS items (
        id INT PRIMARY KEY,
        name VARCHAR(100),
        type VARCHAR(50),
        weight FLOAT,
        description TEXT,
        usable BOOLEAN DEFAULT 1,
        icon_path VARCHAR(255),
        capacity INT DEFAULT 0
    )]])
    dbExec(db, [[CREATE TABLE IF NOT EXISTS player_inventory (
        id INT AUTO_INCREMENT PRIMARY KEY,
        player_id INT,
        item_id INT,
        amount INT DEFAULT 1,
        durability INT DEFAULT 100
    )]])
    local q = dbQuery(db, 'SELECT * FROM items')
    local res = dbPoll(q, -1)
    items = {}
    for _,row in ipairs(res or {}) do
        items[row.id] = row
    end
end

local function init()
    db = exports.pyrp_core:getDB()
    if db then
        loadItemDefinitions()
    end
end
addEventHandler('onResourceStart', resourceRoot, init)

local function getMaxCarry(player)
    local base = 20
    local inv = inventories[player] or {}
    for id,data in pairs(inv) do
        local def = items[id]
        if def and def.capacity and def.capacity > 0 then
            base = base + def.capacity * data.amount
        end
    end
    return base
end

local function recalcWeight(player)
    local inv = inventories[player] or {}
    local w = 0
    for id,data in pairs(inv) do
        local def = items[id]
        if def then
            w = w + (def.weight or 0) * data.amount
        end
    end
    setElementData(player, 'inv:weight', w)
    setElementData(player, 'inv:max', getMaxCarry(player))
end

local function loadInventory(player, accID)
    if not db then return end
    local q = dbQuery(db, 'SELECT item_id,amount,durability FROM player_inventory WHERE player_id=?', accID)
    local res = dbPoll(q, -1)
    local inv = {}
    for _,row in ipairs(res or {}) do
        inv[row.item_id] = {amount=row.amount, durability=row.durability}
    end
    inventories[player] = inv
    recalcWeight(player)
end
addEvent('account:postLogin', true)
addEventHandler('account:postLogin', root, loadInventory)

local function saveInventory(player)
    if not db then return end
    local accID = getElementData(player, 'account:id')
    if not accID then return end
    local inv = inventories[player]
    if not inv then return end
    dbExec(db, 'DELETE FROM player_inventory WHERE player_id=?', accID)
    for id,data in pairs(inv) do
        dbExec(db, 'INSERT INTO player_inventory (player_id,item_id,amount,durability) VALUES (?,?,?,?)',
            accID, id, data.amount, data.durability)
    end
end
addEventHandler('onPlayerQuit', root, saveInventory)
addEventHandler('onResourceStop', resourceRoot, function()
    for _,p in ipairs(getElementsByType('player')) do
        saveInventory(p)
    end
end)

local function canCarry(player, itemId, amount)
    amount = tonumber(amount) or 1
    local def = items[itemId]
    if not def then return false end
    local weight = (getElementData(player, 'inv:weight') or 0) + def.weight * amount
    return weight <= getMaxCarry(player)
end

function giveItem(player, itemId, amount)
    if not items[itemId] then return false end
    amount = tonumber(amount) or 1
    if not canCarry(player, itemId, amount) then
        outputChatBox('Inventory full', player)
        return false
    end
    local inv = inventories[player] or {}
    local entry = inv[itemId] or {amount=0, durability=100}
    entry.amount = entry.amount + amount
    inv[itemId] = entry
    inventories[player] = inv
    recalcWeight(player)
    triggerClientEvent(player, 'inventory:update', resourceRoot, inv, getMaxCarry(player), getElementData(player,'inv:weight'))
    return true
end
addEvent('inventory:giveItem', true)
addEventHandler('inventory:giveItem', root, function(itemId, amount)
    giveItem(client or source, tonumber(itemId), amount)
end)

local function removeItem(player, itemId, amount)
    amount = tonumber(amount) or 1
    local inv = inventories[player]
    if not inv or not inv[itemId] then return false end
    local entry = inv[itemId]
    if entry.amount < amount then amount = entry.amount end
    entry.amount = entry.amount - amount
    if entry.amount <= 0 then inv[itemId] = nil end
    inventories[player] = inv
    local def = items[itemId]
    if def then
        setElementData(player,'inv:weight',(getElementData(player,'inv:weight') or 0) - def.weight * amount)
    end
    recalcWeight(player)
    triggerClientEvent(player, 'inventory:update', resourceRoot, inv, getMaxCarry(player), getElementData(player,'inv:weight'))
    return true
end

addEvent('inventory:removeItem', true)
addEventHandler('inventory:removeItem', root, function(itemId, amount)
    removeItem(client or source, tonumber(itemId), amount)
end)

addCommandHandler('mojinventar', function(p)
    local inv = inventories[p] or {}
    triggerClientEvent(p, 'inventory:show', resourceRoot, inv, getMaxCarry(p), getElementData(p,'inv:weight') or 0, items)
end)

addCommandHandler('darovat', function(p, cmd, targetName, itemId, amount)
    local target = getPlayerFromName(targetName or '')
    itemId = tonumber(itemId)
    amount = tonumber(amount) or 1
    if not target or not itemId then return end
    if removeItem(p, itemId, amount) then
        giveItem(target, itemId, amount)
        outputChatBox('Daroval si '..amount..'x '..(items[itemId] and items[itemId].name or 'item')..' hracovi '..getPlayerName(target), p)
        outputChatBox(getPlayerName(p)..' ti daroval '..amount..'x '..(items[itemId] and items[itemId].name or 'item'), target)
    end
end)

addCommandHandler('odhodit', function(p, cmd, itemId, amount)
    itemId = tonumber(itemId)
    amount = tonumber(amount) or 1
    if removeItem(p, itemId, amount) then
        outputChatBox('Odhodil si '..amount..'x '..(items[itemId] and items[itemId].name or 'item'), p)
        -- Here you would create a world pickup
    end
end)

local function isAdmin(p)
    local acc = getPlayerAccount(p)
    if not acc or isGuestAccount(acc) then return false end
    local group = aclGetGroup('Admin')
    if not group then return false end
    return isObjectInACLGroup('user.'..getAccountName(acc), group)
end

addCommandHandler('vytvorpredmet', function(p, cmd, id, name, typ, weight, cap)
    if not isAdmin(p) then return end
    id = tonumber(id)
    weight = tonumber(weight)
    cap = tonumber(cap) or 0
    if not id or not name or not typ or not weight then
        outputChatBox('Pouzitie: /vytvorpredmet [id] [nazov] [typ] [vaha] [kapacita]', p)
        return
    end
    dbExec(db, 'REPLACE INTO items (id,name,type,weight,capacity) VALUES (?,?,?,?,?)', id, name, typ, weight, cap)
    items[id] = {id=id,name=name,type=typ,weight=weight,capacity=cap}
    outputChatBox('Predmet '..name..' vytvoreny.', p)
end)

-- Export for other resources
function hasItem(player, itemId)
    local inv = inventories[player]
    return inv and inv[itemId]
end
exports('giveItem', giveItem)
exports('removeItem', removeItem)
exports('hasItem', hasItem)

-- Property system server logic for Project Y RP
-- Provides property ownership, rental and lock management similar to Owl Gaming

local db
local properties = {}
local keys = {}
local rentals = {}

local function loadProperties()
    if not db then return end
    properties = {}
    local q = dbQuery(db, 'SELECT * FROM real_estate')
    local res = dbPoll(q, -1)
    for _,row in ipairs(res or {}) do
        row.locked = row.locked == 1
        properties[row.id] = row
    end
    keys = {}
    rentals = {}
    q = dbQuery(db, 'SELECT * FROM property_access')
    res = dbPoll(q, -1)
    for _,row in ipairs(res or {}) do
        if not keys[row.property_id] then keys[row.property_id] = {} end
        keys[row.property_id][row.player_id] = {can_lock=row.can_lock==1, can_manage=row.can_manage==1}
    end
    q = dbQuery(db, 'SELECT * FROM property_rentals')
    res = dbPoll(q, -1)
    for _,row in ipairs(res or {}) do
        rentals[row.property_id] = rentals[row.property_id] or {}
        rentals[row.property_id][row.renter_id] = row.expires_at
    end
end

addEventHandler('onResourceStart', resourceRoot, function()
    db = exports.pyrp_core:getDB()
    if not db then return end
    dbExec(db, [[CREATE TABLE IF NOT EXISTS real_estate (
        id INT AUTO_INCREMENT PRIMARY KEY,
        owner_id INT,
        type VARCHAR(50),
        address VARCHAR(100),
        position_x FLOAT,
        position_y FLOAT,
        position_z FLOAT,
        interior_id INT,
        price INT DEFAULT 0,
        locked BOOLEAN DEFAULT 1,
        is_rentable BOOLEAN DEFAULT 0,
        rent_price INT DEFAULT 0,
        rent_expires DATE,
        tax_due INT DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )]])
    dbExec(db, [[CREATE TABLE IF NOT EXISTS property_access (
        id INT AUTO_INCREMENT PRIMARY KEY,
        property_id INT,
        player_id INT,
        can_lock BOOLEAN DEFAULT 1,
        can_manage BOOLEAN DEFAULT 0
    )]])
    dbExec(db, [[CREATE TABLE IF NOT EXISTS property_rentals (
        id INT AUTO_INCREMENT PRIMARY KEY,
        property_id INT,
        renter_id INT,
        expires_at DATETIME
    )]])
    loadProperties()
end)

local function hasKey(pid, propID)
    local k = keys[propID]
    return k and k[pid]
end

local function saveLockState(propID)
    local prop = properties[propID]
    if prop then
        dbExec(db, 'UPDATE real_estate SET locked=? WHERE id=?', prop.locked and 1 or 0, propID)
    end
end

function toggleLock(player, id)
    id = tonumber(id)
    local prop = properties[id]
    if not prop then return end
    local pid = getElementData(player, 'account:id')
    if pid == prop.owner_id or hasKey(pid, id) then
        prop.locked = not prop.locked
        saveLockState(id)
        outputChatBox('Property '..id..' '..(prop.locked and 'locked' or 'unlocked'), player)
    else
        outputChatBox('You do not have a key for this property', player)
    end
end
addCommandHandler('lockprop', toggleLock)
addEvent('propertySystem:toggleLock', true)
addEventHandler('propertySystem:toggleLock', root, function(id)
    toggleLock(client or source, id)
end)

local function giveKey(player, cmd, id, targetName)
    id = tonumber(id)
    local prop = properties[id]
    if not prop then return end
    local pid = getElementData(player, 'account:id')
    if pid ~= prop.owner_id then
        outputChatBox('You are not the owner', player)
        return
    end
    local target = getPlayerFromName(targetName)
    if not target then return end
    local tid = getElementData(target, 'account:id')
    if not tid then return end
    keys[id] = keys[id] or {}
    keys[id][tid] = {can_lock=true, can_manage=false}
    dbExec(db, 'INSERT INTO property_access (property_id,player_id,can_lock,can_manage) VALUES (?,?,?,?)', id, tid, 1, 0)
    outputChatBox('Gave key to '..getPlayerName(target), player)
    outputChatBox('Received key for property #'..id, target)
end
addCommandHandler('givekey', giveKey)

local function buyProperty(player, cmd, id)
    id = tonumber(id)
    local prop = properties[id]
    if not prop then return end
    if prop.owner_id and prop.owner_id > 0 then
        outputChatBox('Property already owned', player)
        return
    end
    local accID = getElementData(player, 'account:id')
    if not accID then return end
    prop.owner_id = accID
    keys[id] = keys[id] or {}
    keys[id][accID] = {can_lock=true, can_manage=true}
    dbExec(db, 'UPDATE real_estate SET owner_id=? WHERE id=?', accID, id)
    dbExec(db, 'INSERT INTO property_access (property_id,player_id,can_lock,can_manage) VALUES (?,?,?,?)', id, accID, 1, 1)
    outputChatBox('You bought property #'..id, player)
end
addCommandHandler('buyprop', buyProperty)

local function rentProperty(player, cmd, id)
    id = tonumber(id)
    local prop = properties[id]
    if not prop or prop.owner_id == 0 then return end
    if not prop.is_rentable or prop.rent_price <= 0 then
        outputChatBox('Property not for rent', player)
        return
    end
    local accID = getElementData(player, 'account:id')
    if not accID then return end
    local expires = getRealTime().timestamp + 7*24*60*60
    keys[id] = keys[id] or {}
    keys[id][accID] = {can_lock=true, can_manage=false}
    dbExec(db, 'INSERT INTO property_access (property_id,player_id,can_lock,can_manage) VALUES (?,?,?,?)', id, accID, 1, 0)
    dbExec(db, 'INSERT INTO property_rentals (property_id,renter_id,expires_at) VALUES (?,?,FROM_UNIXTIME(?))', id, accID, expires)
    outputChatBox('You rented property #'..id..' for $'..prop.rent_price, player)
end
addCommandHandler('rentprop', rentProperty)

local function listMyProperties(player)
    local pid = getElementData(player, 'account:id')
    if not pid then return end
    outputChatBox('Your properties:', player)
    for id,prop in pairs(properties) do
        if prop.owner_id == pid or hasKey(pid, id) then
            outputChatBox('#'..id..' '..(prop.address or 'unknown')..' ['..(prop.locked and 'Locked' or 'Unlocked')..']', player)
        end
    end
end
addCommandHandler('myproperties', listMyProperties)

-- Export for other resources
function hasPropertyKey(pid, id)
    return hasKey(pid, tonumber(id)) ~= nil
end
exports('hasPropertyKey', hasPropertyKey)

local function enterProperty(player, cmd, id)
    id = tonumber(id)
    local prop = properties[id]
    if not prop then return end
    local pid = getElementData(player, 'account:id')
    if prop.locked and pid ~= prop.owner_id and not hasKey(pid, id) then
        outputChatBox('Door is locked.', player)
        return
    end
    setElementInterior(player, prop.interior_id or 0)
    setElementPosition(player, prop.position_x or 0, prop.position_y or 0, (prop.position_z or 0) + 1)
end
addCommandHandler('enterprop', enterProperty)

local function sellProperty(player, cmd, id)
    id = tonumber(id)
    local prop = properties[id]
    if not prop then return end
    local pid = getElementData(player, 'account:id')
    if pid ~= prop.owner_id then
        outputChatBox('You are not the owner', player)
        return
    end
    prop.owner_id = 0
    keys[id] = nil
    dbExec(db, 'UPDATE real_estate SET owner_id=0 WHERE id=?', id)
    dbExec(db, 'DELETE FROM property_access WHERE property_id=?', id)
    outputChatBox('Property sold back to the city', player)
end
addCommandHandler('sellprop', sellProperty)

local function evictTenant(player, cmd, id, targetName)
    id = tonumber(id)
    local prop = properties[id]
    if not prop then return end
    local pid = getElementData(player, 'account:id')
    if pid ~= prop.owner_id then return end
    local target = getPlayerFromName(targetName)
    if not target then return end
    local tid = getElementData(target, 'account:id')
    if not tid then return end
    if rentals[id] then rentals[id][tid] = nil end
    if keys[id] then keys[id][tid] = nil end
    dbExec(db, 'DELETE FROM property_rentals WHERE property_id=? AND renter_id=?', id, tid)
    dbExec(db, 'DELETE FROM property_access WHERE property_id=? AND player_id=?', id, tid)
    outputChatBox('Tenant evicted', player)
    outputChatBox('You have been evicted from property #'..id, target)
end
addCommandHandler('evicttenant', evictTenant)

local function setPropertyTax(player, cmd, id, amount)
    id = tonumber(id)
    amount = tonumber(amount)
    local prop = properties[id]
    if not prop or not amount then return end
    local pid = getElementData(player, 'account:id')
    if pid ~= prop.owner_id then return end
    prop.tax_due = amount
    dbExec(db, 'UPDATE real_estate SET tax_due=? WHERE id=?', amount, id)
    outputChatBox('Tax updated for property #'..id, player)
end
addCommandHandler('setproptax', setPropertyTax)

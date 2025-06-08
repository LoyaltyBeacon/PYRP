-- Marketplace system server-side

local db

local function init()
    db = exports.pyrp_core:getDB()
    if not db then return end
    dbExec(db, [[CREATE TABLE IF NOT EXISTS marketplace (
        id INT AUTO_INCREMENT PRIMARY KEY,
        seller_id INT NOT NULL,
        item_id INT NOT NULL,
        price INT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )]])
    dbExec(db, [[CREATE TABLE IF NOT EXISTS market_history (
        id INT AUTO_INCREMENT PRIMARY KEY,
        seller_id INT,
        buyer_id INT,
        item_id INT,
        price INT,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
    )]])
end
addEventHandler('onResourceStart', resourceRoot, init)

local LIMIT = 5
local PRICE_MIN = 1
local PRICE_MAX = 1000000

local function hasSpaceForListing(accID)
    if not db then return false end
    local q = dbQuery(db, 'SELECT COUNT(id) AS c FROM marketplace WHERE seller_id=?', accID)
    local r = dbPoll(q, -1)
    return r and r[1] and tonumber(r[1].c) < LIMIT
end

local function addMarketplaceItem(player, itemID, price)
    if not db then return end
    local accID = getElementData(player, 'account:id')
    if not accID or not itemID or not price then return end
    price = tonumber(price)
    itemID = tonumber(itemID)
    if not price or price < PRICE_MIN or price > PRICE_MAX then return end
    if not exports.inventory:hasItem(player, itemID) then return end
    if not hasSpaceForListing(accID) then
        outputChatBox('You reached listing limit', player)
        return
    end
    exports.inventory:removeItem(player, itemID, 1)
    dbExec(db, 'INSERT INTO marketplace (seller_id,item_id,price) VALUES (?,?,?)', accID, itemID, price)
    triggerClientEvent(player, 'market:itemAdded', resourceRoot)
end
addEvent('market:addItem', true)
addEventHandler('market:addItem', root, function(item, price)
    addMarketplaceItem(client or source, item, price)
end)

local function sendListings(player)
    if not db then return end
    local q = dbQuery(db, 'SELECT marketplace.id,item_id,price,seller_id,accounts.username AS seller FROM marketplace JOIN accounts ON accounts.id=marketplace.seller_id LIMIT 50')
    local r = dbPoll(q, -1)
    triggerClientEvent(player, 'market:updateListings', resourceRoot, r or {})
end
addEvent('market:getListings', true)
addEventHandler('market:getListings', root, function()
    sendListings(client or source)
end)

local function sendMyListings(player)
    if not db then return end
    local accID = getElementData(player, 'account:id')
    if not accID then return end
    local q = dbQuery(db, 'SELECT id,item_id,price FROM marketplace WHERE seller_id=?', accID)
    local r = dbPoll(q, -1)
    triggerClientEvent(player, 'market:updateMyListings', resourceRoot, r or {})
end
addEvent('market:getMyListings', true)
addEventHandler('market:getMyListings', root, function()
    sendMyListings(client or source)
end)

local function cancelListing(player, listingID)
    if not db then return end
    local accID = getElementData(player, 'account:id')
    listingID = tonumber(listingID)
    if not accID or not listingID then return end
    local q = dbQuery(db, 'SELECT item_id FROM marketplace WHERE id=? AND seller_id=?', listingID, accID)
    local r = dbPoll(q, -1)
    if not r or not r[1] then return end
    local itemID = tonumber(r[1].item_id)
    dbExec(db, 'DELETE FROM marketplace WHERE id=?', listingID)
    exports.inventory:giveItem(player, itemID, 1)
    triggerClientEvent(player, 'market:updateUI', resourceRoot)
end
addEvent('market:cancelListing', true)
addEventHandler('market:cancelListing', root, function(id)
    cancelListing(client or source, id)
end)

local function depositToAccount(accID, amount)
    if not db or not accID or not amount then return end
    local q = dbQuery(db, 'SELECT id FROM bank_accounts WHERE owner_id=? AND account_type="personal"', accID)
    local r = dbPoll(q, -1)
    if r and r[1] then
        dbExec(db, 'UPDATE bank_accounts SET balance=balance+? WHERE id=?', amount, r[1].id)
        dbExec(db, 'INSERT INTO bank_transactions (account_id,amount,type,description) VALUES (?,?,"payment","market sale")', r[1].id, amount)
    end
end

local function withdrawFromAccount(accID, amount)
    if not db or not accID or not amount then return false end
    local q = dbQuery(db, 'SELECT id,balance FROM bank_accounts WHERE owner_id=? AND account_type="personal"', accID)
    local r = dbPoll(q, -1)
    if r and r[1] and r[1].balance >= amount then
        dbExec(db, 'UPDATE bank_accounts SET balance=balance-? WHERE id=?', amount, r[1].id)
        dbExec(db, 'INSERT INTO bank_transactions (account_id,amount,type,description) VALUES (?,?,"payment","market purchase")', r[1].id, -amount)
        return true
    end
    return false
end

local function buyItem(player, listingID)
    if not db then return end
    listingID = tonumber(listingID)
    if not listingID then return end
    local accID = getElementData(player, 'account:id')
    if not accID then return end
    local q = dbQuery(db, 'SELECT seller_id,item_id,price FROM marketplace WHERE id=?', listingID)
    local r = dbPoll(q, -1)
    if not r or not r[1] then return end
    local row = r[1]
    if not withdrawFromAccount(accID, row.price) then
        outputChatBox('Not enough money', player)
        return
    end
    depositToAccount(row.seller_id, row.price)
    dbExec(db, 'DELETE FROM marketplace WHERE id=?', listingID)
    dbExec(db, 'INSERT INTO market_history (seller_id,buyer_id,item_id,price) VALUES (?,?,?,?)', row.seller_id, accID, row.item_id, row.price)
    exports.inventory:giveItem(player, tonumber(row.item_id), 1)
    triggerClientEvent(player, 'market:updateUI', resourceRoot)
    local seller
    for _,p in ipairs(getElementsByType('player')) do
        if getElementData(p, 'account:id') == row.seller_id then
            seller = p
            break
        end
    end
    if seller then
        triggerClientEvent(seller, 'market:updateUI', resourceRoot)
    end
end
addEvent('market:buyItem', true)
addEventHandler('market:buyItem', root, function(id)
    buyItem(client or source, id)
end)

exports('addMarketplaceItem', addMarketplaceItem)
exports('getMarketplaceListings', sendListings)
exports('getPlayerListings', sendMyListings)

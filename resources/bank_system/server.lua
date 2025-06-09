-- Comprehensive financial system handling player bank accounts, transactions
-- and simple tax and fine records.

local db

addEventHandler('onResourceStart', resourceRoot, function()
    db = exports.pyrp_core:getDB()
    if not db then return end
    dbExec(db, [[CREATE TABLE IF NOT EXISTS bank_accounts (
        id INT AUTO_INCREMENT PRIMARY KEY,
        owner_id INT,
        account_type ENUM('personal','company'),
        balance INT DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )]])
    dbExec(db, [[CREATE TABLE IF NOT EXISTS bank_transactions (
        id INT AUTO_INCREMENT PRIMARY KEY,
        account_id INT,
        amount INT,
        type ENUM('deposit','withdrawal','transfer','payment'),
        description TEXT,
        timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )]])
    dbExec(db, [[CREATE TABLE IF NOT EXISTS tax_records (
        id INT AUTO_INCREMENT PRIMARY KEY,
        entity_type ENUM('player','company'),
        entity_id INT,
        tax_amount INT,
        paid BOOLEAN DEFAULT 0,
        due_date DATE,
        timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )]])
    dbExec(db, [[CREATE TABLE IF NOT EXISTS fines (
        id INT AUTO_INCREMENT PRIMARY KEY,
        player_id INT,
        reason TEXT,
        amount INT,
        issued_by VARCHAR(50),
        paid BOOLEAN DEFAULT 0,
        issued_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )]])
end)

-- ensure personal account exists on login
local function ensurePersonalAccount(_, accID)
    if not db then return end
    local q = dbQuery(db, "SELECT id FROM bank_accounts WHERE owner_id=? AND account_type='personal'", accID)
    local r = dbPoll(q, -1)
    if not r or not r[1] then
        dbExec(db, "INSERT INTO bank_accounts (owner_id,account_type,balance) VALUES (?,?,0)", accID, 'personal')
    end
end
addEvent('account:postLogin', true)
addEventHandler('account:postLogin', root, ensurePersonalAccount)

local function getAccountID(accID)
    local q = dbQuery(db, "SELECT id FROM bank_accounts WHERE owner_id=? AND account_type='personal' LIMIT 1", accID)
    local r = dbPoll(q, -1)
    return r and r[1] and tonumber(r[1].id)
end

local function getBalance(accID)
    local id = getAccountID(accID)
    if not id then return 0 end
    local q = dbQuery(db, "SELECT balance FROM bank_accounts WHERE id=?", id)
    local r = dbPoll(q, -1)
    return r and r[1] and tonumber(r[1].balance) or 0
end

function depositMoney(player, amount, desc)
    if not db then return end
    local accID = getElementData(player, 'account:id')
    if not accID then return end
    amount = tonumber(amount) or 0
    if amount <= 0 then return end
    local id = getAccountID(accID)
    if not id then return end
    dbExec(db, 'UPDATE bank_accounts SET balance=balance+? WHERE id=?', amount, id)
    dbExec(db, 'INSERT INTO bank_transactions (account_id,amount,type,description) VALUES (?,?,?,?)',
        id, amount, 'deposit', desc or '')
    outputChatBox('Deposited $'..amount, player)
end
addEvent('bank:deposit', true)
addEventHandler('bank:deposit', root, depositMoney)

function withdrawMoney(player, amount, desc)
    if not db then return end
    local accID = getElementData(player, 'account:id')
    if not accID then return end
    amount = tonumber(amount) or 0
    if amount <= 0 then return end
    local id = getAccountID(accID)
    if not id then return end
    local bal = getBalance(accID)
    if bal < amount then
        outputChatBox('Insufficient funds', player)
        return
    end
    dbExec(db, 'UPDATE bank_accounts SET balance=balance-? WHERE id=?', amount, id)
    dbExec(db, 'INSERT INTO bank_transactions (account_id,amount,type,description) VALUES (?,?,?,?)',
        id, -amount, 'withdrawal', desc or '')
    outputChatBox('Withdrew $'..amount, player)
end
addEvent('bank:withdraw', true)
addEventHandler('bank:withdraw', root, withdrawMoney)

local function transferMoney(player, targetName, amount)
    if not db then return end
    local accID = getElementData(player, 'account:id')
    if not accID then return end
    local target = getPlayerFromName(targetName)
    if not target then return end
    local targetAcc = getElementData(target, 'account:id')
    if not targetAcc then return end
    amount = tonumber(amount) or 0
    if amount <= 0 then return end
    local bal = getBalance(accID)
    if bal < amount then
        outputChatBox('Insufficient funds', player)
        return
    end
    local fromID = getAccountID(accID)
    local toID = getAccountID(targetAcc)
    if not fromID or not toID then return end
    dbExec(db, 'UPDATE bank_accounts SET balance=balance-? WHERE id=?', amount, fromID)
    dbExec(db, 'UPDATE bank_accounts SET balance=balance+? WHERE id=?', amount, toID)
    dbExec(db, 'INSERT INTO bank_transactions (account_id,amount,type,description) VALUES (?,?,?,?)',
        fromID, -amount, 'transfer', 'to '..targetAcc)
    dbExec(db, 'INSERT INTO bank_transactions (account_id,amount,type,description) VALUES (?,?,?,?)',
        toID, amount, 'transfer', 'from '..accID)
    outputChatBox('Transferred $'..amount..' to '..getPlayerName(target), player)
end

addCommandHandler('prevod', function(p, cmd, target, amount)
    transferMoney(p, target, amount)
end)

addCommandHandler('mojucet', function(p)
    local acc = getElementData(p, 'account:id')
    if not acc then return end
    outputChatBox('Balance: $'..getBalance(acc), p)
end)

addCommandHandler('zostatok', function(p)
    local acc = getElementData(p, 'account:id')
    if not acc then return end
    outputChatBox('Balance: $'..getBalance(acc), p)
end)

addCommandHandler('zaplatitpokutu', function(p)
    if not db then return end
    local accID = getElementData(p, 'account:id')
    if not accID then return end
    local q = dbQuery(db, 'SELECT id,amount FROM fines WHERE player_id=? AND paid=0', accID)
    local rows = dbPoll(q, -1)
    local total = 0
    for _,r in ipairs(rows or {}) do total = total + r.amount end
    if total == 0 then outputChatBox('No outstanding fines', p) return end
    local bal = getBalance(accID)
    if bal < total then outputChatBox('Not enough money to pay fines', p) return end
    local acc = getAccountID(accID)
    dbExec(db, 'UPDATE bank_accounts SET balance=balance-? WHERE id=?', total, acc)
    dbExec(db, 'INSERT INTO bank_transactions (account_id,amount,type,description) VALUES (?,?,?,?)',
        acc, -total, 'payment', 'fines')
    dbExec(db, 'UPDATE fines SET paid=1 WHERE player_id=? AND paid=0', accID)
    outputChatBox('Paid fines of $'..total, p)
end)

addCommandHandler('priznatdan', function(p, cmd, amount)
    if not db then return end
    local accID = getElementData(p, 'account:id')
    if not accID then return end
    amount = tonumber(amount)
    if not amount or amount <= 0 then return end
    dbExec(db, 'INSERT INTO tax_records (entity_type,entity_id,tax_amount,paid,due_date) VALUES ("player",?,?,0,DATE_ADD(NOW(), INTERVAL 7 DAY))',
        accID, amount)
    outputChatBox('Tax of $'..amount..' declared', p)
end)

-- Exports for other resources
function getPlayerBalance(accID)
    return getBalance(accID)
end

exports('depositMoney', depositMoney)
exports('withdrawMoney', withdrawMoney)
exports('getPlayerBalance', getPlayerBalance)

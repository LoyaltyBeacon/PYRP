-- Phone system for Project Y RP

local db
local phoneNumbers = {}

local function initDB()
    db = exports.pyrp_core:getDB()
    if not db then return end
    dbExec(db, [[CREATE TABLE IF NOT EXISTS phones (
        id INT AUTO_INCREMENT PRIMARY KEY,
        player_id INT,
        phone_number VARCHAR(15) UNIQUE,
        active BOOLEAN DEFAULT 1,
        is_locked BOOLEAN DEFAULT 0,
        pin_code VARCHAR(6)
    )]])
    dbExec(db, [[CREATE TABLE IF NOT EXISTS phone_calls (
        id INT AUTO_INCREMENT PRIMARY KEY,
        caller_number VARCHAR(15),
        receiver_number VARCHAR(15),
        start_time TIMESTAMP,
        end_time TIMESTAMP,
        duration INT
    )]])
    dbExec(db, [[CREATE TABLE IF NOT EXISTS phone_messages (
        id INT AUTO_INCREMENT PRIMARY KEY,
        sender_number VARCHAR(15),
        receiver_number VARCHAR(15),
        message TEXT,
        timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )]])
    dbExec(db, [[CREATE TABLE IF NOT EXISTS phone_contacts (
        id INT AUTO_INCREMENT PRIMARY KEY,
        phone_id INT,
        contact_name VARCHAR(100),
        contact_number VARCHAR(15)
    )]])
end
addEventHandler('onResourceStart', resourceRoot, initDB)

local function loadPhones(player)
    if not db then return end
    local accID = getElementData(player, 'account:id')
    if not accID then return end
    local q = dbQuery(db, 'SELECT * FROM phones WHERE player_id=?', accID)
    local res = dbPoll(q, -1)
    if res and res[1] then
        phoneNumbers[player] = res[1].phone_number
    else
        -- create phone with random number
        local number = tostring(math.random(100000,999999))
        dbExec(db, 'INSERT INTO phones (player_id, phone_number) VALUES (?,?)', accID, number)
        phoneNumbers[player] = number
    end
end
addEventHandler('onPlayerLogin', root, function(_,acc)
    loadPhones(source)
end)

addEventHandler('onPlayerQuit', root, function()
    phoneNumbers[source] = nil
end)

local function findPlayerByNumber(number)
    for p,num in pairs(phoneNumbers) do
        if num == number then return p end
    end
    return nil
end

-- Commands
local function cmdPhoneInfo(player)
    local number = phoneNumbers[player]
    if number then
        outputChatBox('Your phone number: '..number, player)
    else
        outputChatBox('No phone available', player)
    end
end
addCommandHandler('mojetelefon', cmdPhoneInfo)

local function cmdSMS(player, cmd, number, ...)
    if not number then
        outputChatBox('Usage: /sms [number] [text]', player)
        return
    end
    local text = table.concat({...}, ' ')
    local sender = phoneNumbers[player]
    if not sender then return end
    local targetPlayer = findPlayerByNumber(number)
    if targetPlayer then
        outputChatBox('[SMS from '..sender..']: '..text, targetPlayer)
        outputChatBox('SMS sent to '..number, player)
    else
        outputChatBox('Number not available', player)
    end
    if db then
        dbExec(db, 'INSERT INTO phone_messages (sender_number, receiver_number, message) VALUES (?,?,?)', sender, number, text)
    end
end
addCommandHandler('sms', cmdSMS)

local activeCalls = {}

local function cmdCall(player, cmd, number)
    if not number then
        outputChatBox('Usage: /zavolat [number]', player)
        return
    end
    local from = phoneNumbers[player]
    local target = findPlayerByNumber(number)
    if not target then
        outputChatBox('Number unavailable', player)
        return
    end
    if activeCalls[player] or activeCalls[target] then
        outputChatBox('Line busy', player)
        return
    end
    activeCalls[player] = target
    activeCalls[target] = player
    outputChatBox('Connecting call...', player)
    outputChatBox('Incoming call from '..from..'. Use /prijat or /odmietnut.', target)
end
addCommandHandler('zavolat', cmdCall)

local function endCall(p1, p2)
    activeCalls[p1] = nil
    activeCalls[p2] = nil
end

local function cmdPrijat(player)
    local caller = activeCalls[player]
    if not caller then return end
    outputChatBox('Call connected.', player)
    outputChatBox('Call answered.', caller)
    -- store start time
    setElementData(player, 'callStart', getRealTime().timestamp)
    setElementData(caller, 'callStart', getRealTime().timestamp)
end
addCommandHandler('prijat', cmdPrijat)

local function cmdOdmietnut(player)
    local caller = activeCalls[player]
    if caller then
        outputChatBox('Call declined.', player)
        outputChatBox('Call rejected.', caller)
        endCall(player, caller)
    end
end
addCommandHandler('odmietnut', cmdOdmietnut)

local function cmdZavesit(player)
    local target = activeCalls[player]
    if not target then return end
    local start = getElementData(player, 'callStart') or getRealTime().timestamp
    local duration = getRealTime().timestamp - start
    local from = phoneNumbers[player]
    local to = phoneNumbers[target]
    if db then
        dbExec(db, 'INSERT INTO phone_calls (caller_number, receiver_number, start_time, end_time, duration) VALUES (?,?,?,?,?)', from, to, start, getRealTime().timestamp, duration)
    end
    outputChatBox('Call ended.', player)
    outputChatBox('Call ended.', target)
    endCall(player, target)
end
addCommandHandler('zavesit', cmdZavesit)

-- Contact management (add/remove/list)
local function cmdKontakt(player, cmd, action, name, number)
    local phone = phoneNumbers[player]
    if not phone then return end
    if action == 'prida' and name and number then
        local q = dbQuery(db, 'SELECT id FROM phones WHERE phone_number=?', phone)
        local res = dbPoll(q, -1)
        if res and res[1] then
            dbExec(db, 'INSERT INTO phone_contacts (phone_id, contact_name, contact_number) VALUES (?,?,?)', res[1].id, name, number)
            outputChatBox('Contact added.', player)
        end
    elseif action == 'odstran' and name then
        local q = dbQuery(db, 'SELECT id FROM phones WHERE phone_number=?', phone)
        local res = dbPoll(q, -1)
        if res and res[1] then
            dbExec(db, 'DELETE FROM phone_contacts WHERE phone_id=? AND contact_name=?', res[1].id, name)
            outputChatBox('Contact removed.', player)
        end
    else
        -- list
        local q = dbQuery(db, [[SELECT contact_name, contact_number FROM phone_contacts WHERE phone_id=(SELECT id FROM phones WHERE phone_number=?)]], phone)
        local res = dbPoll(q, -1)
        if res then
            outputChatBox('--- Contacts ---', player)
            for _,row in ipairs(res) do
                outputChatBox(row.contact_name..' - '..row.contact_number, player)
            end
        end
    end
end
addCommandHandler('telefonkontakt', cmdKontakt)

-- Account system server logic with MySQL persistence and hashed passwords
local db
local loginAttempts = {}
local function randToken()
    return string.sub(md5(tostring(math.random()) .. tostring(getTickCount())), 1, 16)
end

local function initDB()
    local host = get('mysql.host') or 'localhost'
    local dbname = get('mysql.dbname') or 'pyrp'
    local user = get('mysql.user') or 'root'
    local pass = get('mysql.pass') or ''
    db = dbConnect('mysql', string.format('dbname=%s;host=%s', dbname, host), user, pass)
    if db then
        dbExec(db, [[CREATE TABLE IF NOT EXISTS accounts (
            id INT AUTO_INCREMENT PRIMARY KEY,
            username VARCHAR(32) UNIQUE,
            password VARCHAR(64),
            email VARCHAR(128),
            trust_score INT DEFAULT 50,
            discord_id VARCHAR(32),
            twofactor_code VARCHAR(6),
            web_token VARCHAR(32),
            last_login DATETIME
        )]])
        dbExec(db, [[CREATE TABLE IF NOT EXISTS characters (
            id INT AUTO_INCREMENT PRIMARY KEY,
            account_id INT,
            name VARCHAR(32),
            gender VARCHAR(10),
            posX FLOAT, posY FLOAT, posZ FLOAT
        )]])
    else
        outputServerLog('Account system DB connection failed')
    end
end
addEventHandler('onResourceStart', resourceRoot, initDB)

local function notify(p, msg)
    triggerClientEvent(p, 'account:notify', resourceRoot, msg)
end

function registerAccount(player, username, password, email)
    if not db then return end
    if not username or #username < 3 then return notify(player, 'Username too short') end
    if not password or #password < 6 then return notify(player, 'Password too short') end

    local q = dbQuery(db, 'SELECT id FROM accounts WHERE username=?', username)
    local result = dbPoll(q, -1)
    if result and result[1] then
        notify(player, 'Account already exists')
        return
    end

    local hashPass = hash('sha256', password)
    dbExec(db, 'INSERT INTO accounts (username,password,email,trust_score,last_login) VALUES (?,?,?,?,NOW())',
        username, hashPass, email or '', 50)
    triggerClientEvent(player, 'account:registered', resourceRoot, username)
end
addEvent('account:register', true)
addEventHandler('account:register', root, registerAccount)

function loginAccount(player, username, password, code)
    if not db then return end
    local data = loginAttempts[player] or {count=0, lock=0}
    if data.lock > getTickCount() then
        notify(player, 'Too many attempts. Please wait.')
        return
    end

    local hashPass = hash('sha256', password)
    local q = dbQuery(db, 'SELECT id,twofactor_code,trust_score FROM accounts WHERE username=? AND password=?', username, hashPass)
    local result = dbPoll(q, -1)
    if result and result[1] then
        local row = result[1]
        if row.twofactor_code and row.twofactor_code ~= '' then
            if code ~= row.twofactor_code then
                notify(player, '2FA code required')
                return
            end
        end
        loginAttempts[player] = nil
        local accID = row.id
        setElementData(player, 'account:id', accID)
        setElementData(player, 'account:name', username)
        setElementData(player, 'account:trust', row.trust_score)
        dbExec(db, 'UPDATE accounts SET last_login=NOW() WHERE id=?', accID)
        -- notify other resources of successful login
        triggerEvent('account:postLogin', player, accID)
        triggerClientEvent(player, 'account:onLogin', resourceRoot, username, row.trust_score)
    else
        data.count = data.count + 1
        if data.count >= 3 then
            data.lock = getTickCount() + 30000
            data.count = 0
        end
        loginAttempts[player] = data
        notify(player, 'Invalid credentials')
    end
end
addEvent('account:login', true)
addEventHandler('account:login', root, loginAccount)

-- Update account trust score
function adjustTrust(player, amount)
    if not db then return end
    local accID = getElementData(player, 'account:id')
    if not accID then return end
    local newScore = math.max(0, math.min(100, (getElementData(player, 'account:trust') or 50) + amount))
    setElementData(player, 'account:trust', newScore)
    dbExec(db, 'UPDATE accounts SET trust_score=? WHERE id=?', newScore, accID)
end
addEvent('account:adjustTrust', true)
addEventHandler('account:adjustTrust', root, adjustTrust)

function generateWebToken(player)
    if not db then return nil end
    local accID = getElementData(player, 'account:id')
    local name = getElementData(player, 'account:name')
    if not accID or not name then return nil end
    local token = randToken()
    dbExec(db, 'UPDATE accounts SET web_token=? WHERE id=?', token, accID)
    return token, name
end
addEvent('account:requestWebToken', true)
addEventHandler('account:requestWebToken', root, function()
    local t, name = generateWebToken(client or source)
    if t then
        triggerClientEvent(client or source, 'account:receiveWebToken', resourceRoot, name, t)
    end
end)
exports('generateWebToken', generateWebToken)

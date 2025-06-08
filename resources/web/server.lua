-- City Web server logic for Project Y RP

local db

local function init()
    db = exports.pyrp_core:getDB()
    if not db then return end
    dbExec(db, [[CREATE TABLE IF NOT EXISTS city_records (
        id INT AUTO_INCREMENT PRIMARY KEY,
        type ENUM('pokuta','dane','volby','event','audity'),
        player_id INT,
        description TEXT,
        timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )]])
    dbExec(db, [[CREATE TABLE IF NOT EXISTS city_elections (
        id INT AUTO_INCREMENT PRIMARY KEY,
        candidate_id INT,
        votes INT DEFAULT 0,
        round INT,
        active BOOLEAN DEFAULT 1
    )]])
    dbExec(db, [[CREATE TABLE IF NOT EXISTS city_announcements (
        id INT AUTO_INCREMENT PRIMARY KEY,
        title VARCHAR(100),
        content TEXT,
        posted_by VARCHAR(50),
        timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )]])
    dbExec(db, [[CREATE TABLE IF NOT EXISTS taxes (
        id INT AUTO_INCREMENT PRIMARY KEY,
        player_id INT,
        amount INT
    )]])
end
addEventHandler('onResourceStart', resourceRoot, init)

local function sendAnnouncements(player)
    if not db then return end
    local q = dbQuery(db, 'SELECT id,title,content,posted_by FROM city_announcements ORDER BY timestamp DESC LIMIT 5')
    local res = dbPoll(q, -1) or {}
    triggerClientEvent(player, 'web:showAnnouncements', resourceRoot, res)
end
addEvent('web:requestAnnouncements', true)
addEventHandler('web:requestAnnouncements', root, function()
    sendAnnouncements(client or source)
end)

local function sendPlayerRecords(player)
    if not db then return end
    local pid = getElementData(player, 'account:id')
    if not pid then return end
    local q = dbQuery(db, 'SELECT type,description FROM city_records WHERE player_id=?', pid)
    local res = dbPoll(q, -1) or {}
    triggerClientEvent(player, 'web:showRecords', resourceRoot, res)
end
addEvent('web:requestMyRecords', true)
addEventHandler('web:requestMyRecords', root, function()
    sendPlayerRecords(client or source)
end)

local function sendPlayerTaxes(player)
    if not db then return end
    local pid = getElementData(player, 'account:id')
    if not pid then return end
    local q = dbQuery(db, 'SELECT amount FROM taxes WHERE player_id=?', pid)
    local res = dbPoll(q, -1) or {}
    triggerClientEvent(player, 'web:showTaxes', resourceRoot, res)
end
addEvent('web:requestTaxes', true)
addEventHandler('web:requestTaxes', root, function()
    sendPlayerTaxes(client or source)
end)

local function listCandidates(player)
    if not db then return end
    local q = dbQuery(db, 'SELECT id,candidate_id,votes FROM city_elections WHERE active=1')
    local res = dbPoll(q, -1) or {}
    outputChatBox('--- Candidates ---', player)
    for _,row in ipairs(res) do
        outputChatBox('#'..row.id..' candidate '..row.candidate_id..' - '..row.votes..' votes', player)
    end
end
addCommandHandler('volby', listCandidates)

local function vote(player, cmd, id)
    id = tonumber(id)
    if not id then
        outputChatBox('Usage: /hlasovat [id]', player)
        return
    end
    if not db then return end
    dbExec(db, 'UPDATE city_elections SET votes=votes+1 WHERE id=? AND active=1', id)
    outputChatBox('Thanks for voting!', player)
end
addCommandHandler('hlasovat', vote)

-- Export for client to request open
function openCityWeb(player)
    sendAnnouncements(player)
    sendPlayerRecords(player)
    sendPlayerTaxes(player)
end
exports('openCityWeb', openCityWeb)

addEvent('web:requestOpen', true)
addEventHandler('web:requestOpen', root, function()
    local player = client or source
    local token, name = exports.account_system:generateWebToken(player)
    if token and name then
        triggerClientEvent(player, 'web:openUrl', resourceRoot, name, token)
    end
end)

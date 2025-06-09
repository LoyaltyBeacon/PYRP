-- Politics and Election system

local db

addEventHandler('onResourceStart', resourceRoot, function()
    db = exports.pyrp_core:getDB()
    if not db then return end
    dbExec(db, [[CREATE TABLE IF NOT EXISTS candidates (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(100),
        character_id INT,
        slogan TEXT,
        description TEXT,
        status ENUM('active','ended') DEFAULT 'active'
    )]])
    dbExec(db, [[CREATE TABLE IF NOT EXISTS votes (
        id INT AUTO_INCREMENT PRIMARY KEY,
        voter_id INT,
        candidate_id INT,
        timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )]])
    dbExec(db, [[CREATE TABLE IF NOT EXISTS mayor_settings (
        `key` VARCHAR(50) PRIMARY KEY,
        `value` TEXT
    )]])
end)

local REG_FEE = 2000

local function getCharacterID(plr)
    return getElementData(plr, 'character:id')
end

local function hasVoted(charID)
    if not db then return false end
    local q = dbQuery(db, 'SELECT id FROM votes WHERE voter_id=?', charID)
    local r = dbPoll(q, -1)
    return r and r[1]
end

function registerCandidate(player, slogan, desc)
    if not db then return end
    local charID = getCharacterID(player)
    if not charID then return end
    if hasVoted(charID) then
        outputChatBox('Nemôžeš kandidovať po hlasovaní.', player)
        return
    end
    local q = dbQuery(db, 'SELECT id FROM candidates WHERE character_id=? AND status="active"', charID)
    local r = dbPoll(q, -1)
    if r and r[1] then
        outputChatBox('Už si registrovaný ako kandidát.', player)
        return
    end
    local bal = exports.bank_system:getPlayerBalance(getElementData(player, 'account:id'))
    if bal < REG_FEE then
        outputChatBox('Potrebuješ $'..REG_FEE..' na registráciu.', player)
        return
    end
    exports.bank_system:withdrawMoney(player, REG_FEE, 'candidate fee')
    dbExec(db, 'INSERT INTO candidates (name,character_id,slogan,description) VALUES (?,?,?,?)',
        getPlayerName(player), charID, slogan or '', desc or '')
    outputChatBox('Kandidát zaregistrovaný.', player)
end
addCommandHandler('kandidat', function(plr, cmd, ...)
    local slogan = table.concat({...}, ' ')
    registerCandidate(plr, slogan)
end)

function voteForCandidate(player, id)
    if not db then return end
    id = tonumber(id)
    local charID = getCharacterID(player)
    if not charID or not id then return end
    if hasVoted(charID) then
        outputChatBox('Už si hlasoval.', player)
        return
    end
    local q = dbQuery(db, 'SELECT id FROM candidates WHERE id=? AND status="active"', id)
    local r = dbPoll(q, -1)
    if not r or not r[1] then
        outputChatBox('Neplatný kandidát.', player)
        return
    end
    dbExec(db, 'INSERT INTO votes (voter_id,candidate_id) VALUES (?,?)', charID, id)
    outputChatBox('Ďakujeme za hlas!', player)
end

addCommandHandler('hlasuj', function(plr, cmd, id)
    voteForCandidate(plr, id)
end)

local function announceWinner(winnerID)
    if not db or not winnerID then return end
    local q = dbQuery(db, 'SELECT name FROM candidates WHERE id=?', winnerID)
    local r = dbPoll(q, -1)
    local name = r and r[1] and r[1].name or tostring(winnerID)
    outputChatBox('Novým starostom je '..name..'!', root)
    dbExec(db, 'REPLACE INTO mayor_settings (`key`,`value`) VALUES ("mayor_char",?)', winnerID)
end

function endVoting()
    if not db then return end
    local q = dbQuery(db, 'SELECT candidate_id, COUNT(*) AS c FROM votes GROUP BY candidate_id ORDER BY c DESC LIMIT 1')
    local r = dbPoll(q, -1)
    if not r or not r[1] then
        outputChatBox('Žiadni kandidáti.', root)
        return
    end
    local winner = r[1].candidate_id
    announceWinner(winner)
    dbExec(db, 'UPDATE candidates SET status="ended"')
    dbExec(db, 'DELETE FROM votes')
end

function getVotingStatus(player)
    if not db then return end
    local q = dbQuery(db, 'SELECT id,name,slogan FROM candidates WHERE status="active"')
    local res = dbPoll(q, -1) or {}
    triggerClientEvent(player, 'politics:showCandidates', resourceRoot, res)
end
addCommandHandler('volby', function(p, cmd, arg, id)
    if arg == 'start' then
        dbExec(db, 'DELETE FROM candidates')
        dbExec(db, 'DELETE FROM votes')
        outputChatBox('Začala registrácia kandidátov.', root)
    elseif arg == 'hlasuj' then
        voteForCandidate(p, id)
    elseif arg == 'koniec' then
        endVoting()
    else
        getVotingStatus(p)
    end
end)

function broadcastMayorNews(player, text)
    if not db then return end
    local charID = getCharacterID(player)
    local q = dbQuery(db, 'SELECT `value` FROM mayor_settings WHERE `key`="mayor_char"')
    local r = dbPoll(q, -1)
    local mayor = r and r[1] and tonumber(r[1].value)
    if charID and mayor and charID == mayor then
        outputChatBox('[Starosta] '..text, root)
    else
        outputChatBox('Nie si starosta.', player)
    end
end
addCommandHandler('oznamstarosta', function(plr, cmd, ...)
    local msg = table.concat({...}, ' ')
    if msg ~= '' then
        broadcastMayorNews(plr, msg)
    end
end)

exports('registerCandidate', registerCandidate)
exports('voteForCandidate', voteForCandidate)
exports('endVoting', endVoting)
exports('getVotingStatus', getVotingStatus)
exports('broadcastMayorNews', broadcastMayorNews)

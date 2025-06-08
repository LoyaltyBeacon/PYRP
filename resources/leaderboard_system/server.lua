-- Leaderboard system generating top players and factions
local db

addEventHandler('onResourceStart', resourceRoot, function()
    db = exports.pyrp_core:getDB()
end)

function generateTopPlayers(jobType)
    if not db then return {} end
    local q = dbQuery(db, [[SELECT player_id, level, xp FROM player_skills
        WHERE skill_name=? ORDER BY xp DESC LIMIT 10]], jobType)
    local rows = dbPoll(q, -1)
    return rows or {}
end

function getRichestPlayers()
    if not db then return {} end
    local q = dbQuery(db, [[SELECT owner_id AS player_id, balance FROM bank_accounts
        WHERE account_type='personal' ORDER BY balance DESC LIMIT 10]])
    local rows = dbPoll(q, -1)
    return rows or {}
end

function getFactionStats()
    if exports.faction_system and exports.faction_system.getFactionStats then
        return exports.faction_system:getFactionStats()
    end
    return {}
end

function getMostWantedPlayers()
    if not db then return {} end
    local q = dbQuery(db, [[SELECT player_id, level FROM wanted_levels
        ORDER BY level DESC LIMIT 10]])
    local rows = dbPoll(q, -1)
    return rows or {}
end

local function printList(p, list, fmt)
    for i,data in ipairs(list) do
        outputChatBox(string.format(fmt, i, data.player_id or data.name or '', data.level or data.balance or data.members or ''), p)
    end
end

addCommandHandler('rebricek', function(p, cmd, typ, arg)
    if typ == 'job' and arg then
        local list = generateTopPlayers(arg)
        outputChatBox('TOP 10 '..arg..' players:', p, 255,255,0)
        printList(p, list, '%d. ID:%s XP:%s')
    elseif typ == 'bohati' then
        local list = getRichestPlayers()
        outputChatBox('Najbohatsie ucty:', p, 255,255,0)
        printList(p, list, '%d. ID:%s $%s')
    elseif typ == 'wanted' then
        local list = getMostWantedPlayers()
        outputChatBox('Najhladanejsi hraci:', p, 255,255,0)
        printList(p, list, '%d. ID:%s Wanted:%s')
    elseif typ == 'fakcie' then
        local list = getFactionStats()
        outputChatBox('Najaktivnejsie frakcie:', p, 255,255,0)
        for i,data in ipairs(list) do
            outputChatBox(string.format('%d. %s (%d clenov)', i, data.name, data.members), p)
        end
    else
        outputChatBox('/rebricek job [skill] | bohati | wanted | fakcie', p)
    end
end)

exports('generateTopPlayers', generateTopPlayers)
exports('getRichestPlayers', getRichestPlayers)
exports('getFactionStats', getFactionStats)
exports('getMostWantedPlayers', getMostWantedPlayers)

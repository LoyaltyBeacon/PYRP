-- Skill system server logic
local db

addEventHandler('onResourceStart', resourceRoot, function()
    db = exports.pyrp_core:getDB()
    if not db then return end
    dbExec(db, [[CREATE TABLE IF NOT EXISTS player_skills (
        player_id INT,
        skill_name VARCHAR(50),
        level INT DEFAULT 1,
        xp INT DEFAULT 0,
        last_updated INT,
        PRIMARY KEY(player_id,skill_name)
    )]])
end)

local function loadSkills(player, accID)
    if not db then return end
    local q = dbQuery(db, 'SELECT skill_name, level, xp FROM player_skills WHERE player_id=?', accID)
    local result = dbPoll(q, -1)
    local skills = {}
    if result then
        for _, row in ipairs(result) do
            skills[row.skill_name] = {level=row.level, xp=row.xp}
        end
    end
    setElementData(player, 'skills', skills)
end

local function saveSkills(player)
    if not db then return end
    local accID = getElementData(player, 'account:id')
    if not accID then return end
    local skills = getElementData(player, 'skills') or {}
    for name,data in pairs(skills) do
        dbExec(db, 'REPLACE INTO player_skills (player_id,skill_name,level,xp,last_updated) VALUES (?,?,?,?,?)',
            accID, name, data.level or 1, data.xp or 0, getRealTime().timestamp)
    end
end

addEventHandler('onPlayerQuit', root, function()
    saveSkills(source)
end)

addEvent('account:postLogin', true)
addEventHandler('account:postLogin', root, function(accID)
    loadSkills(source, accID)
end)

function getSkillLevel(player, name)
    local skills = getElementData(player, 'skills') or {}
    return (skills[name] and skills[name].level) or 1
end

local function addSkillXP(player, name, amount)
    local skills = getElementData(player, 'skills') or {}
    local data = skills[name] or {level=1, xp=0}
    local mult = 1.0
    if exports.vip_system then
        mult = exports.vip_system:getVipMultiplier(player)
    end
    local add = math.floor(amount * mult)
    data.xp = data.xp + add
    local needed = data.level * 100
    while data.xp >= needed and data.level < 10 do
        data.xp = data.xp - needed
        data.level = data.level + 1
        outputChatBox(name..' skill level '..data.level, player)
        needed = data.level * 100
    end
    skills[name] = data
    setElementData(player, 'skills', skills)
end
addEvent('skill:addXP', true)
addEventHandler('skill:addXP', root, addSkillXP)

addCommandHandler('mojeskilly', function(plr)
    local skills = getElementData(plr, 'skills') or {}
    for name,data in pairs(skills) do
        outputChatBox(name..': lvl '..data.level..' ('..data.xp..'xp)', plr)
    end
end)

addCommandHandler('ucls', function(plr, cmd, targetName, skill)
    local lvl = getSkillLevel(plr, skill or '')
    if lvl < 8 then return end
    local target = getPlayerFromName(targetName or '')
    if isElement(target) then
        addSkillXP(target, skill, 10)
        outputChatBox('Teaching '..skill..' to '..getPlayerName(target), plr)
    end
end)

exports('getSkillLevel', getSkillLevel)
exports('addSkillXP', addSkillXP)

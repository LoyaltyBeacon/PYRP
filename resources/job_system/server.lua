-- Employment Office and job management
local db
local jobs = {}
local active = {}

local function loadJobs()
    if not db then return end
    jobs = {}
    local q = dbQuery(db, 'SELECT * FROM jobs')
    local res = dbPoll(q, -1)
    if res then
        for _,row in ipairs(res) do
            jobs[row.id] = row
        end
    end
end

addEventHandler('onResourceStart', resourceRoot, function()
    db = exports.pyrp_core:getDB()
    if not db then return end
    dbExec(db, [[CREATE TABLE IF NOT EXISTS jobs (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(50),
        required_license VARCHAR(50),
        min_level INT DEFAULT 0,
        description TEXT
    )]])
    dbExec(db, [[CREATE TABLE IF NOT EXISTS job_history (
        id INT AUTO_INCREMENT PRIMARY KEY,
        player_id INT,
        job_id INT,
        start_date DATETIME,
        end_date DATETIME,
        reason TEXT
    )]])
    dbExec(db, [[CREATE TABLE IF NOT EXISTS active_jobs (
        player_id INT PRIMARY KEY,
        job_id INT,
        start_time DATETIME
    )]])
    loadJobs()
end)

local function checkJobRequirements(player, job)
    if job.required_license and job.required_license ~= '' then
        if not (exports.education_system and exports.education_system:hasCertificate(player, job.required_license)) then
            return false, 'Missing license: '..job.required_license
        end
    end
    if job.min_level and exports.skill_system then
        local lvl = exports.skill_system:getSkillLevel(player, job.name)
        if lvl < job.min_level then
            return false, 'Requires level '..job.min_level
        end
    end
    return true
end

function applyForJob(player, jobID)
    jobID = tonumber(jobID)
    local job = jobs[jobID]
    if not job then return end
    local ok, msg = checkJobRequirements(player, job)
    if not ok then
        outputChatBox(msg, player, 255,0,0)
        triggerEvent('onJobRequirementFail', player, jobID, msg)
        return
    end
    local accID = getElementData(player, 'account:id')
    if not accID then return end
    if active[accID] then
        resignFromJob(player)
    end
    active[accID] = {job_id=jobID, start=getRealTime().timestamp}
    dbExec(db, 'REPLACE INTO active_jobs (player_id,job_id,start_time) VALUES (?,?,NOW())', accID, jobID)
    dbExec(db, 'INSERT INTO job_history (player_id,job_id,start_date) VALUES (?,?,NOW())', accID, jobID)
    setElementData(player, 'job', job.name)
    triggerEvent('onPlayerJobChange', player, jobID)
    outputChatBox('Zamestnaný ako '..job.name, player, 0,255,0)
end
addCommandHandler('zamestnaj', function(p,cmd,id) applyForJob(p,id) end)
addEvent('employment:apply', true)
addEventHandler('employment:apply', root, function(id) applyForJob(client or source, id) end)

function resignFromJob(player)
    local accID = getElementData(player,'account:id')
    if not accID or not active[accID] then return end
    local jobID = active[accID].job_id
    dbExec(db, 'DELETE FROM active_jobs WHERE player_id=?', accID)
    dbExec(db, 'UPDATE job_history SET end_date=NOW() WHERE player_id=? AND job_id=? AND end_date IS NULL', accID, jobID)
    active[accID] = nil
    setElementData(player,'job', nil)
    triggerEvent('onPlayerJobResign', player, jobID)
    outputChatBox('Prácu si ukončil.', player)
end
addCommandHandler('ukoncipracu', resignFromJob)
addEvent('employment:resign', true)
addEventHandler('employment:resign', root, function() resignFromJob(client or source) end)

function getJobHistory(player)
    local accID = getElementData(player,'account:id')
    if not accID or not db then return {} end
    local q = dbQuery(db, 'SELECT j.name, h.start_date, h.end_date FROM job_history h JOIN jobs j ON j.id=h.job_id WHERE player_id=?', accID)
    local res = dbPoll(q, -1) or {}
    return res
end
addEvent('employment:getHistory', true)
addEventHandler('employment:getHistory', root, function()
    local data = getJobHistory(client or source)
    triggerClientEvent(client or source, 'employment:receiveHistory', resourceRoot, data)
end)

function showJobList(player)
    for id,job in pairs(jobs) do
        outputChatBox(id..') '..job.name..' - '..(job.description or 'No info'), player)
    end
end
addCommandHandler('jobs', showJobList)
addEvent('employment:getList', true)
addEventHandler('employment:getList', root, function() showJobList(client or source) end)

addEvent('account:postLogin', true)
addEventHandler('account:postLogin', root, function(accID)
    if not db then return end
    local q = dbQuery(db, 'SELECT job_id FROM active_jobs WHERE player_id=?', accID)
    local res = dbPoll(q, -1)
    if res and res[1] and jobs[res[1].job_id] then
        active[accID] = {job_id=res[1].job_id}
        setElementData(source, 'job', jobs[res[1].job_id].name)
    end
end)

exports('applyForJob', applyForJob)
exports('resignFromJob', resignFromJob)
exports('getJobHistory', getJobHistory)
exports('showJobList', showJobList)

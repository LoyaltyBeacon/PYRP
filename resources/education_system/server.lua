-- Education system server-side
local db

local function init()
    db = exports.pyrp_core:getDB()
    if not db then return end
    dbExec(db, [[CREATE TABLE IF NOT EXISTS certificates (
        id INT AUTO_INCREMENT PRIMARY KEY,
        player_id INT NOT NULL,
        type VARCHAR(32),
        granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )]])
    dbExec(db, [[CREATE TABLE IF NOT EXISTS education_tests (
        id INT AUTO_INCREMENT PRIMARY KEY,
        course_id INT,
        question TEXT,
        answer1 TEXT,
        answer2 TEXT,
        answer3 TEXT,
        correct_answer INT
    )]])
end
addEventHandler('onResourceStart', resourceRoot, init)

local function hasCertificate(player, certType)
    if not db then return false end
    local accID = getElementData(player, 'account:id')
    if not accID then return false end
    local q = dbQuery(db, 'SELECT id FROM certificates WHERE player_id=? AND type=?', accID, certType)
    local r = dbPoll(q, -1)
    return r and r[1] ~= nil
end

local function grantCertificate(player, certType)
    if not db then return end
    local accID = getElementData(player, 'account:id')
    if not accID or hasCertificate(player, certType) then return end
    dbExec(db, 'INSERT INTO certificates (player_id,type) VALUES (?,?)', accID, certType)
    outputChatBox('You received certificate: '..certType, player, 0, 255, 0)
end

function startTheoryTest(player, courseID)
    outputChatBox('Starting theory test for course '..tostring(courseID), player)
end
addEvent('education:startTheoryTest', true)
addEventHandler('education:startTheoryTest', root, function(course)
    startTheoryTest(client or source, course)
end)

function submitTheoryAnswers(player, courseID, score)
    outputChatBox('Theory test score: '..tostring(score), player)
    if tonumber(score) >= 70 then
        grantCertificate(player, courseID)
    else
        outputChatBox('You failed the theory test.', player, 255, 0, 0)
    end
end
addEvent('education:submitTheoryAnswers', true)
addEventHandler('education:submitTheoryAnswers', root, function(course, score)
    submitTheoryAnswers(client or source, course, score)
end)

exports('hasCertificate', hasCertificate)
exports('grantCertificate', grantCertificate)

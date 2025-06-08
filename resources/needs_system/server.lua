-- Needs system server logic for Project Y RP
local db

local function init()
    db = exports.pyrp_core:getDB()
    if not db then return end
    dbExec(db, [[CREATE TABLE IF NOT EXISTS hunger_status (
        player_id INT PRIMARY KEY,
        hunger INT DEFAULT 100,
        thirst INT DEFAULT 100,
        energy INT DEFAULT 100,
        last_update TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )]])
    setTimer(function()
        for _,plr in ipairs(getElementsByType('player')) do
            local accID = getElementData(plr, 'account:id')
            if accID then
                local hunger = getElementData(plr, 'need:hunger') or 100
                local thirst = getElementData(plr, 'need:thirst') or 100
                local energy = getElementData(plr, 'need:energy') or 100
                local mult = 1.0
                if exports.vip_system and exports.vip_system.getVipMultiplier then
                    mult = exports.vip_system:getVipMultiplier(plr) or 1.0
                end
                hunger = hunger - 1 / mult
                thirst = thirst - 1.5 / mult
                energy = energy - 2 / mult
                if hunger < 0 then hunger = 0 end
                if thirst < 0 then thirst = 0 end
                if energy < 0 then energy = 0 end
                setElementData(plr, 'need:hunger', hunger)
                setElementData(plr, 'need:thirst', thirst)
                setElementData(plr, 'need:energy', energy)
                if hunger == 0 or thirst == 0 then
                    setElementHealth(plr, math.max(0, getElementHealth(plr)-5))
                end
            end
        end
    end, 300000, 0)
end
addEventHandler('onResourceStart', resourceRoot, init)

local function loadNeeds(player, accID)
    if not db then return end
    local q = dbQuery(db, 'SELECT * FROM hunger_status WHERE player_id=?', accID)
    local r = dbPoll(q, -1)
    if r and r[1] then
        setElementData(player, 'need:hunger', r[1].hunger)
        setElementData(player, 'need:thirst', r[1].thirst)
        setElementData(player, 'need:energy', r[1].energy)
    else
        dbExec(db, 'INSERT INTO hunger_status (player_id) VALUES (?)', accID)
        setElementData(player, 'need:hunger', 100)
        setElementData(player, 'need:thirst', 100)
        setElementData(player, 'need:energy', 100)
    end
end
addEvent('account:postLogin', true)
addEventHandler('account:postLogin', root, loadNeeds)

local function saveNeeds(player)
    if not db then return end
    local accID = getElementData(player, 'account:id')
    if not accID then return end
    dbExec(db, 'REPLACE INTO hunger_status (player_id,hunger,thirst,energy,last_update) VALUES (?,?,?,?,NOW())',
        accID,
        math.floor(getElementData(player,'need:hunger') or 100),
        math.floor(getElementData(player,'need:thirst') or 100),
        math.floor(getElementData(player,'need:energy') or 100))
end
addEventHandler('onPlayerQuit', root, saveNeeds)
addEventHandler('onResourceStop', resourceRoot, function()
    for _,p in ipairs(getElementsByType('player')) do
        saveNeeds(p)
    end
end)

local function eatCmd(p)
    local hunger = math.min(100, (getElementData(p,'need:hunger') or 100) + 40)
    setElementData(p,'need:hunger', hunger)
    outputChatBox('You ate some food. Hunger: '..math.floor(hunger)..'%', p)
end
addCommandHandler('zjest', eatCmd)

local function drinkCmd(p)
    local thirst = math.min(100, (getElementData(p,'need:thirst') or 100) + 50)
    setElementData(p,'need:thirst', thirst)
    outputChatBox('You drank something. Thirst: '..math.floor(thirst)..'%', p)
end
addCommandHandler('pit', drinkCmd)

local function sleepCmd(p)
    local energy = math.min(100, (getElementData(p,'need:energy') or 100) + 50)
    setElementData(p,'need:energy', energy)
    outputChatBox('You feel rested. Energy: '..math.floor(energy)..'%', p)
end
addCommandHandler('spat', sleepCmd)

addCommandHandler('stavpostavy', function(p)
    local h = getElementData(p,'need:hunger') or 100
    local t = getElementData(p,'need:thirst') or 100
    local e = getElementData(p,'need:energy') or 100
    outputChatBox(string.format('Hunger: %.0f%%  Thirst: %.0f%%  Energy: %.0f%%', h,t,e), p)
end)

function getNeeds(player)
    return getElementData(player,'need:hunger'), getElementData(player,'need:thirst'), getElementData(player,'need:energy')
end
exports('getNeeds', getNeeds)

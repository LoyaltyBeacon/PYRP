-- Vehicle system for Project Y RP
-- Handles vehicle ownership, locking, STK and insurance

local db
local playerVehicles = {}

local function initDB()
    db = exports.pyrp_core:getDB()
    if not db then return end
    dbExec(db, [[CREATE TABLE IF NOT EXISTS vehicles (
        id INT AUTO_INCREMENT PRIMARY KEY,
        owner_id INT,
        plate VARCHAR(15),
        model VARCHAR(50),
        color VARCHAR(20),
        mileage INT DEFAULT 0,
        fuel FLOAT DEFAULT 100,
        health INT DEFAULT 1000,
        locked BOOLEAN DEFAULT 1,
        registered BOOLEAN DEFAULT 1,
        last_stk DATE,
        insurance_active BOOLEAN DEFAULT 0,
        insurance_expiry DATE
    )]])
    dbExec(db, [[CREATE TABLE IF NOT EXISTS vehicle_inspection (
        vehicle_id INT PRIMARY KEY,
        last_check DATE,
        inspector_id INT,
        status ENUM('OK','Zlyhanie') DEFAULT 'OK',
        notes TEXT,
        next_due DATE
    )]])
    dbExec(db, [[CREATE TABLE IF NOT EXISTS vehicle_insurance (
        vehicle_id INT PRIMARY KEY,
        type ENUM('Ziadne','PZP','Havarijne') DEFAULT 'Ziadne',
        active BOOLEAN DEFAULT 0,
        expiry_date DATE,
        price INT,
        purchase_date DATE
    )]])
end
addEventHandler('onResourceStart', resourceRoot, initDB)

local function loadVehicles(_, accID)
    if not db then return end
    local q = dbQuery(db, 'SELECT * FROM vehicles WHERE owner_id=?', accID)
    local res = dbPoll(q, -1)
    playerVehicles[accID] = res or {}
end
addEvent('account:postLogin', true)
addEventHandler('account:postLogin', root, loadVehicles)

local function getAccID(p)
    return getElementData(p, 'account:id')
end

local function nearestOwnedVehicle(player)
    local accID = getAccID(player)
    if not accID then return nil end
    local px,py,pz = getElementPosition(player)
    local best,dist
    for _,veh in ipairs(getElementsByType('vehicle')) do
        local vid = getElementData(veh, 'veh:id')
        if vid then
            for _,data in ipairs(playerVehicles[accID] or {}) do
                if data.id == vid then
                    local vx,vy,vz = getElementPosition(veh)
                    local d = getDistanceBetweenPoints3D(px,py,pz,vx,vy,vz)
                    if not dist or d < dist then
                        dist = d
                        best = veh
                    end
                end
            end
        end
    end
    return best
end

local function toggleLock(player)
    local veh = nearestOwnedVehicle(player)
    if not veh then return end
    local locked = not isVehicleLocked(veh)
    setVehicleLocked(veh, locked)
    outputChatBox('Vehicle '..(locked and 'locked' or 'unlocked'), player)
end
addCommandHandler('zamknutauto', toggleLock)

local function startEngine(player)
    local veh = getPedOccupiedVehicle(player)
    if veh and getVehicleController(veh) == player then
        local locked = isVehicleLocked(veh)
        if locked then outputChatBox('Vehicle is locked', player) return end
        setVehicleEngineState(veh, not getVehicleEngineState(veh))
    end
end
addCommandHandler('nastartuj', startEngine)

local function showMyVehicles(player)
    local accID = getAccID(player)
    if not accID then return end
    outputChatBox('Your vehicles:', player)
    for _,v in ipairs(playerVehicles[accID] or {}) do
        outputChatBox('#'..v.id..' '..(v.plate or v.model), player)
    end
end
addCommandHandler('mojevozidla', showMyVehicles)

local function fuelStatus(player)
    local veh = getPedOccupiedVehicle(player) or nearestOwnedVehicle(player)
    if not veh then return end
    local fuel = getElementData(veh, 'veh:fuel') or 100
    outputChatBox('Fuel: '..string.format('%.1f', fuel), player)
end
addCommandHandler('palivo', fuelStatus)

local function vehicleInfo(player, cmd, id)
    id = tonumber(id)
    if not id or not db then return end
    local q = dbQuery(db, 'SELECT * FROM vehicle_inspection WHERE vehicle_id=?', id)
    local resI = dbPoll(q, -1)
    q = dbQuery(db, 'SELECT * FROM vehicle_insurance WHERE vehicle_id=?', id)
    local resP = dbPoll(q, -1)
    if resI and resI[1] then
        outputChatBox('STK status: '..resI[1].status..' next due '..tostring(resI[1].next_due), player)
    else
        outputChatBox('No STK record', player)
    end
    if resP and resP[1] and resP[1].active == 1 then
        outputChatBox('Insurance: '..resP[1].type..' expires '..tostring(resP[1].expiry_date), player)
    else
        outputChatBox('No active insurance', player)
    end
end
addCommandHandler('vozidloinfo', vehicleInfo)

-- export for other resources
function getPlayerVehicles(accID)
    return playerVehicles[accID] or {}
end
exports('getPlayerVehicles', getPlayerVehicles)

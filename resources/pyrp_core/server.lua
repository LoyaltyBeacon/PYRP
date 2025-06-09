-- Project Y RP - Core server script
local db

-- Initialize MySQL connection
function initDB()
    local host = get( 'mysql.host' ) or 'localhost'
    local dbname = get( 'mysql.dbname' ) or 'pyrp'
    local user = get( 'mysql.user' ) or 'root'
    local pass = get( 'mysql.pass' ) or ''
    db = dbConnect( 'mysql', string.format('dbname=%s;host=%s', dbname, host), user, pass )
    if not db then
        outputServerLog('Unable to connect to database')
    end
end
addEventHandler('onResourceStart', resourceRoot, initDB)

-- Player data loading
function loadPlayerData( player )
    if not db then return end
    local query = dbQuery(db, 'SELECT * FROM players WHERE id=?', getElementData(player, 'dbid'))
    local result = dbPoll(query, -1)
    if result and result[1] then
        setElementData(player, 'health_status', result[1].health_status)
        setElementData(player, 'hunger_status', result[1].hunger_status)
    end
end
addEvent('pyrp:loadPlayerData', true)
addEventHandler('pyrp:loadPlayerData', root, loadPlayerData)

-- Data saving example
function savePlayerData(player)
    if not db then return end
    local health = getElementData(player, 'health_status')
    local hunger = getElementData(player, 'hunger_status')
    dbExec(db, 'UPDATE players SET health_status=?, hunger_status=? WHERE id=?', health, hunger, getElementData(player, 'dbid'))
end
addEvent('pyrp:savePlayerData', true)
addEventHandler('pyrp:savePlayerData', root, savePlayerData)

-- Allow other resources to access the database connection
function getDB()
    return db
end

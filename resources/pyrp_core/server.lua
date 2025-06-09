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

-- Allow other resources to access the database connection
function getDB()
    return db
end

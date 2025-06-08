-- VIP system server logic
local db

addEventHandler('onResourceStart', resourceRoot, function()
    db = exports.pyrp_core:getDB()
    if not db then return end
    dbExec(db, [[CREATE TABLE IF NOT EXISTS vip_status (
        account_id INT PRIMARY KEY,
        tier ENUM('bronze','silver','gold'),
        expires_at INT,
        granted_by VARCHAR(50)
    )]])
end)

local function getTierFromRow(row)
    if not row or not row.tier then return nil end
    if row.expires_at and row.expires_at < getRealTime().timestamp then
        return nil
    end
    return row.tier
end

function getVipTier(player)
    if not db then return nil end
    local accID = getElementData(player, 'account:id')
    if not accID then return nil end
    local q = dbQuery(db, 'SELECT tier, expires_at FROM vip_status WHERE account_id=?', accID)
    local r = dbPoll(q, -1)
    return getTierFromRow(r and r[1])
end
addEvent('vip:getTier', true)
addEventHandler('vip:getTier', root, function()
    local tier = getVipTier(client)
    triggerClientEvent(client, 'vip:returnTier', resourceRoot, tier)
end)

local function dailyBonus(player, tier)
    if not tier then return end
    local bonus = 0
    if tier == 'bronze' then bonus = 50
    elseif tier == 'silver' then bonus = 75
    elseif tier == 'gold' then bonus = 100 end
    if bonus > 0 then
        triggerEvent('bank:deposit', player, bonus)
    end
end

addEvent('account:postLogin', true)
addEventHandler('account:postLogin', root, function(accID)
    local tier = getVipTier(source)
    if tier then
        outputChatBox('VIP status: '..tier, source)
        dailyBonus(source, tier)
    end
end)

function buyVip(player, tier)
    if not db then return end
    tier = tier:lower()
    local allowed = {bronze=true, silver=true, gold=true}
    if not allowed[tier] then
        outputChatBox('Invalid VIP tier', player)
        return
    end
    local accID = getElementData(player, 'account:id')
    if not accID then return end
    local expires = getRealTime().timestamp + 30*24*60*60
    dbExec(db, 'REPLACE INTO vip_status (account_id,tier,expires_at,granted_by) VALUES (?,?,?,?)',
        accID, tier, expires, getPlayerName(player))
    outputChatBox('Purchased VIP: '..tier, player)
end
addCommandHandler('kupitvip', function(plr, cmd, tier)
    if tier then buyVip(plr, tier) end
end)

addCommandHandler('vipinfo', function(plr)
    local tier = getVipTier(plr)
    if tier then
        outputChatBox('You are '..tier..' VIP', plr)
    else
        outputChatBox('No VIP status', plr)
    end
end)

function getVipMultiplier(player)
    local tier = getVipTier(player)
    if tier == 'silver' or tier == 'gold' then
        return 1.1
    end
    return 1.0
end
exports('getVipMultiplier', getVipMultiplier)
exports('getVipTier', getVipTier)

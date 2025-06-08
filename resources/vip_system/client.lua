-- VIP client helper
addEvent('vip:returnTier', true)
addEventHandler('vip:returnTier', root, function(tier)
    if tier then
        outputChatBox('Your VIP status: '..tier)
    else
        outputChatBox('You have no VIP status')
    end
end)

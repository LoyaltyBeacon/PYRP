-- Admin system client script
addEvent('admin:onAdminDuty', true)
addEventHandler('admin:onAdminDuty', root, function(level)
    outputChatBox('Admin duty level '..tostring(level))
end)

-- Simple client helper for viewing events
addEvent('events:receiveList', true)
addEventHandler('events:receiveList', root, function(list)
    for _,ev in ipairs(list) do
        outputChatBox('[EVENT] #'..ev.id..' '..ev.title..' '..ev.datetime)
    end
end)

addCommandHandler('eventy', function()
    triggerServerEvent('events:requestList', localPlayer)
end)

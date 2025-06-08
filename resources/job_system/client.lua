-- Job system client-side helpers
function requestJobList()
    triggerServerEvent('employment:getList', resourceRoot)
end

function applyForJob(id)
    triggerServerEvent('employment:apply', resourceRoot, id)
end

function resignJob()
    triggerServerEvent('employment:resign', resourceRoot)
end

function requestHistory()
    triggerServerEvent('employment:getHistory', resourceRoot)
end

addEvent('employment:receiveHistory', true)
addEventHandler('employment:receiveHistory', resourceRoot, function(list)
    for _,h in ipairs(list) do
        outputChatBox(string.format('%s from %s to %s', h.name, h.start_date or '-', h.end_date or '-'))
    end
end)

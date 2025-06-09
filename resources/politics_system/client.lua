-- Politics system client helpers
addEvent('politics:showCandidates', true)
addEventHandler('politics:showCandidates', root, function(list)
    outputChatBox('--- Kandidáti ---')
    for _,row in ipairs(list) do
        outputChatBox('#'..row.id..' '..row.name..' - '..row.slogan)
    end
end)

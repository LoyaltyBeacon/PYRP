-- City Web client script

local function showAnnouncements(list)
    outputChatBox('--- Announcements ---')
    for _,row in ipairs(list) do
        outputChatBox(row.title..': '..row.content)
    end
end
addEvent('web:showAnnouncements', true)
addEventHandler('web:showAnnouncements', root, showAnnouncements)

local function showRecords(list)
    if #list > 0 then
        outputChatBox('--- Your Records ---')
        for _,r in ipairs(list) do
            outputChatBox(r.type..': '..r.description)
        end
    else
        outputChatBox('No records found.')
    end
end
addEvent('web:showRecords', true)
addEventHandler('web:showRecords', root, showRecords)

local function openWeb()
    triggerServerEvent('web:requestOpen', localPlayer)
    triggerServerEvent('web:requestAnnouncements', localPlayer)
    triggerServerEvent('web:requestMyRecords', localPlayer)
    triggerServerEvent('web:requestTaxes', localPlayer)
end
addCommandHandler('mestskyweb', openWeb)

local browser
addEvent('web:openUrl', true)
addEventHandler('web:openUrl', root, function(name, token)
    if not browser then
        browser = guiCreateBrowser(0.2, 0.15, 0.6, 0.7, true, true, false)
    end
    local b = guiGetBrowser(browser)
    local url = 'http://localhost/index.html?username='..urlEncode(name)..'&token='..urlEncode(token)
    loadBrowserURL(b, url)
    showCursor(true)
end)

addEvent('web:showTaxes', true)
addEventHandler('web:showTaxes', root, function(list)
    if #list > 0 then
        local total = 0
        for _,r in ipairs(list) do total = total + (tonumber(r.amount) or 0) end
        outputChatBox('Outstanding taxes: $'..total)
    else
        outputChatBox('No taxes owed.')
    end
end)

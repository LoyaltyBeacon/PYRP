-- Character system client GUI
local charWindow
local charGrid
local createBtn
local selectBtn

local function requestList()
    triggerServerEvent('characterSystem:getList', localPlayer)
end

addEvent('characterSystem:receiveList', true)
addEventHandler('characterSystem:receiveList', root, function(list)
    if isElement(charWindow) then destroyElement(charWindow) end
    charWindow = guiCreateWindow(0.35, 0.3, 0.3, 0.5, 'Select Character', true)
    guiWindowSetSizable(charWindow, false)
    charGrid = guiCreateGridList(0.05, 0.1, 0.9, 0.6, true, charWindow)
    guiGridListAddColumn(charGrid, 'Name', 0.6)
    guiGridListAddColumn(charGrid, 'Gender', 0.3)
    for _,c in ipairs(list) do
        local r = guiGridListAddRow(charGrid)
        guiGridListSetItemText(charGrid, r, 1, c.name, false, false)
        guiGridListSetItemText(charGrid, r, 2, c.gender, false, false)
        guiGridListSetItemData(charGrid, r, 1, c.id)
    end
    selectBtn = guiCreateButton(0.05, 0.75, 0.4, 0.1, 'Select', true, charWindow)
    createBtn = guiCreateButton(0.55, 0.75, 0.4, 0.1, 'Create', true, charWindow)

    addEventHandler('onClientGUIClick', selectBtn, function()
        local row = guiGridListGetSelectedItem(charGrid)
        if row ~= -1 then
            local id = guiGridListGetItemData(charGrid, row, 1)
            triggerServerEvent('characterSystem:select', localPlayer, id)
            destroyElement(charWindow)
        end
    end, false)

    addEventHandler('onClientGUIClick', createBtn, function()
        local nameWindow = guiCreateWindow(0.4,0.4,0.2,0.15,'New Character',true)
        local edit = guiCreateEdit(0.05,0.4,0.9,0.3,'',true,nameWindow)
        local ok = guiCreateButton(0.3,0.75,0.4,0.2,'Create',true,nameWindow)
        addEventHandler('onClientGUIClick', ok, function()
            local text = guiGetText(edit)
            if text ~= '' then
                triggerServerEvent('characterSystem:create', localPlayer, text, 'Male')
                destroyElement(nameWindow)
            end
        end, false)
    end, false)
end)

addEventHandler('onClientResourceStart', resourceRoot, requestList)

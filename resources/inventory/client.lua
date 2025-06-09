-- Inventory system client script for Project Y RP

local invWindow
local grid
local weightLabel

local function refreshList(data, maxWeight, curWeight)
    if not isElement(invWindow) then return end
    guiGridListClear(grid)
    for id,info in pairs(data) do
        local row = guiGridListAddRow(grid)
        guiGridListSetItemText(grid, row, 1, tostring(id), false, false)
        guiGridListSetItemText(grid, row, 2, tostring(info.amount), false, false)
        guiGridListSetItemText(grid, row, 3, info.name or '', false, false)
    end
    guiSetText(weightLabel, string.format('Weight: %.1f / %.1f', curWeight, maxWeight))
end

addEvent('inventory:show', true)
addEventHandler('inventory:show', root, function(data, maxWeight, curWeight, defs)
    if isElement(invWindow) then destroyElement(invWindow) end
    invWindow = guiCreateWindow(0.35,0.3,0.3,0.5,'Inventar',true)
    guiWindowSetSizable(invWindow,false)
    grid = guiCreateGridList(0.05,0.1,0.9,0.75,true,invWindow)
    guiGridListAddColumn(grid,'ID',0.2)
    guiGridListAddColumn(grid,'Qty',0.2)
    guiGridListAddColumn(grid,'Name',0.5)
    weightLabel = guiCreateLabel(0.05,0.87,0.9,0.08,'',true,invWindow)
    refreshList(data, maxWeight, curWeight)
    local close = guiCreateButton(0.35,0.93,0.3,0.06,'Close',true,invWindow)
    addEventHandler('onClientGUIClick', close, function() destroyElement(invWindow) showCursor(false) end,false)
    showCursor(true)
end)

addEvent('inventory:update', true)
addEventHandler('inventory:update', root, function(data, maxWeight, curWeight)
    refreshList(data, maxWeight, curWeight)
end)

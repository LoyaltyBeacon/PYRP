-- Simple marketplace client GUI
local win, grid, myGrid

local function refresh()
    triggerServerEvent('market:getListings', localPlayer)
    triggerServerEvent('market:getMyListings', localPlayer)
end

addEvent('market:updateListings', true)
addEventHandler('market:updateListings', root, function(list)
    if not isElement(grid) then return end
    guiGridListClear(grid)
    for _,row in ipairs(list) do
        local r = guiGridListAddRow(grid)
        guiGridListSetItemText(grid, r, 1, tostring(row.item_id), false, true)
        guiGridListSetItemText(grid, r, 2, tostring(row.price), false, true)
        guiGridListSetItemText(grid, r, 3, row.seller or '', false, false)
        guiGridListSetItemData(grid, r, 1, row.id)
    end
end)

addEvent('market:updateMyListings', true)
addEventHandler('market:updateMyListings', root, function(list)
    if not isElement(myGrid) then return end
    guiGridListClear(myGrid)
    for _,row in ipairs(list) do
        local r = guiGridListAddRow(myGrid)
        guiGridListSetItemText(myGrid, r, 1, tostring(row.item_id), false, true)
        guiGridListSetItemText(myGrid, r, 2, tostring(row.price), false, true)
        guiGridListSetItemData(myGrid, r, 1, row.id)
    end
end)

addEvent('market:itemAdded', true)
addEventHandler('market:itemAdded', root, refresh)
addEvent('market:updateUI', true)
addEventHandler('market:updateUI', root, refresh)

local function createUI()
    win = guiCreateWindow(0.3,0.25,0.4,0.5,'Marketplace',true)
    local tabP = guiCreateTabPanel(0.02,0.08,0.96,0.9,true,win)
    local tab1 = guiCreateTab('Offers',tabP)
    grid = guiCreateGridList(0.02,0.05,0.96,0.8,true,tab1)
    guiGridListAddColumn(grid,'Item',0.3)
    guiGridListAddColumn(grid,'Price',0.3)
    guiGridListAddColumn(grid,'Seller',0.3)
    local buyBtn = guiCreateButton(0.35,0.87,0.3,0.1,'Buy',true,tab1)
    addEventHandler('onClientGUIClick', buyBtn,function()
        local r = guiGridListGetSelectedItem(grid)
        if r ~= -1 then
            local id = guiGridListGetItemData(grid,r,1)
            triggerServerEvent('market:buyItem', localPlayer, id)
        end
    end,false)

    local tab2 = guiCreateTab('My listings',tabP)
    myGrid = guiCreateGridList(0.02,0.05,0.96,0.8,true,tab2)
    guiGridListAddColumn(myGrid,'Item',0.4)
    guiGridListAddColumn(myGrid,'Price',0.4)
    local cancelBtn = guiCreateButton(0.35,0.87,0.3,0.1,'Cancel',true,tab2)
    addEventHandler('onClientGUIClick', cancelBtn,function()
        local r = guiGridListGetSelectedItem(myGrid)
        if r ~= -1 then
            local id = guiGridListGetItemData(myGrid,r,1)
            triggerServerEvent('market:cancelListing', localPlayer, id)
        end
    end,false)
    local closeBtn = guiCreateButton(0.4,0.92,0.2,0.07,'Close',true,win)
    addEventHandler('onClientGUIClick', closeBtn,function()
        destroyElement(win)
        showCursor(false)
    end,false)
    showCursor(true)
    refresh()
end

addCommandHandler('trhovisko', function()
    if not isElement(win) then
        createUI()
    end
end)

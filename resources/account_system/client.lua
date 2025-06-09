-- Advanced account system client script with login/registration GUI
local loginWindow
local userEdit
local passEdit
local emailEdit
local codeEdit
local actionBtn
local toggleBtn
local registerMode = false

local function submit()
    local user = guiGetText(userEdit)
    local pass = guiGetText(passEdit)
    if registerMode then
        local email = guiGetText(emailEdit)
        triggerServerEvent('account:register', localPlayer, user, pass, email)
    else
        local code = guiGetText(codeEdit)
        triggerServerEvent('account:login', localPlayer, user, pass, code)
    end
end

local function switchMode()
    registerMode = not registerMode
    guiSetVisible(emailEdit, registerMode)
    guiSetVisible(codeEdit, not registerMode)
    guiSetText(actionBtn, registerMode and "Create Account" or "Login")
    guiSetText(toggleBtn, registerMode and "Back to Login" or "Register")
end

local function showLogin()
    loginWindow = guiCreateWindow(0.35,0.3,0.3,0.38,'Project Y Account',true)
    guiWindowSetSizable(loginWindow,false)

    guiCreateLabel(0.05,0.15,0.9,0.1,'Username:',true,loginWindow)
    userEdit = guiCreateEdit(0.05,0.25,0.9,0.1,'',true,loginWindow)

    guiCreateLabel(0.05,0.40,0.9,0.1,'Password:',true,loginWindow)
    passEdit = guiCreateEdit(0.05,0.50,0.9,0.1,'',true,loginWindow)
    guiEditSetMasked(passEdit,true)


    guiCreateLabel(0.05,0.65,0.9,0.1,'Email:',true,loginWindow)
    emailEdit = guiCreateEdit(0.05,0.75,0.9,0.1,'',true,loginWindow)
    guiSetVisible(emailEdit,false)

    guiCreateLabel(0.05,0.55,0.9,0.1,'2FA Code:',true,loginWindow)
    codeEdit = guiCreateEdit(0.05,0.63,0.9,0.1,'',true,loginWindow)
    guiSetVisible(codeEdit,false)

    actionBtn = guiCreateButton(0.05,0.88,0.4,0.1,'Login',true,loginWindow)
    toggleBtn = guiCreateButton(0.55,0.88,0.4,0.1,'Register',true,loginWindow)

    addEventHandler('onClientGUIClick', actionBtn, submit, false)
    addEventHandler('onClientGUIClick', toggleBtn, switchMode, false)
    showCursor(true)
end
addEventHandler('onClientResourceStart', resourceRoot, showLogin)

addEvent('account:onLogin', true)
addEventHandler('account:onLogin', root, function(name, trust)
    if isElement(loginWindow) then destroyElement(loginWindow) end
    showCursor(false)
    outputChatBox('Welcome '..name..' | TrustScore: '..tostring(trust))
    triggerServerEvent('characterSystem:getList', localPlayer)
end)

addEvent('account:registered', true)
addEventHandler('account:registered', root, function(name)
    outputChatBox('Account '..name..' created. You can now log in.')
end)

addEvent('account:notify', true)
addEventHandler('account:notify', root, function(msg)
    outputChatBox(msg)
end)

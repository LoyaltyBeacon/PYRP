-- Health system client script

function onPlayerHealed()
    outputChatBox('You have been healed!')
end
addEvent('healthSystem:onHealed', true)
addEventHandler('healthSystem:onHealed', root, onPlayerHealed)

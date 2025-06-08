-- Education system client-side
addEvent('education:startTheory', true)
addEventHandler('education:startTheory', root, function(course)
    outputChatBox('Theory test for course '..tostring(course)..' started.')
end)

addEvent('education:onCertificate', true)
addEventHandler('education:onCertificate', root, function(cert)
    outputChatBox('Certificate obtained: '..tostring(cert))
end)

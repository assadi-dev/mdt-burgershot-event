local Config = lib.require('config')

RegisterNetEvent('mdt-burgershot-event:client:notify', function(title, message)
    if GetInvokingResource() then return end
    SendNUIMessage({ action = 'playRing' })
    SendNUIMessage({ action = 'notify', title = title, message = message, duration = Config.NotifyDuration })
end)

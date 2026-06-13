local Config = lib.require('config')

RegisterNetEvent('mdt-burgershot-event:client:notify', function(title, message)
    if GetInvokingResource() then return end
    SendNUIMessage({ action = 'playRing' })
    SendNUIMessage({ action = 'notify', title = title, message = message, duration = Config.NotifyDuration })
end)

RegisterNetEvent('mdt-burgershot-event:client:announce', function(title, message)
    if GetInvokingResource() then return end
    SendNUIMessage({ action = 'playRing' })
    SendNUIMessage({ action = 'announce', title = title, message = message, duration = math.floor(Config.NotifyDuration * 1.5) })
end)

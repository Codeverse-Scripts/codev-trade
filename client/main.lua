local requestReceived = false
local sender = nil

RegisterCommand("trade", function(src, args)
    local id = tonumber(args[1])

    if not id then return end

    triggerServerCallback("codev-trade:checkIsOnline", function(cb)
        if cb then
            TriggerServerEvent("codev-trade:sendRequest", id)
        else
            Config.Notify("Error", "Player is not online", "error", 5000)
        end
    end, id)
end, false)

RegisterCommand("accept", function(src, args)
    if requestReceived then
        TriggerServerEvent("codev-trade:acceptRequest", sender)
    else
        Config.Notify("Error", "You have not received a trade request", "error", 5000)
    end
end, false)

RegisterCommand("reject", function(src, args)
    if requestReceived then
        TriggerServerEvent("codev-trade:declineRequest", sender)
        sender = nil
        requestReceived = false
    else
        Config.Notify("Error", "You have not received a trade request", "error", 5000)
    end
end, false)

RegisterNetEvent("codev-trade:requestReceived", function(senderId, senderName)
    requestReceived = true
    sender = senderId
    Config.Notify("Received", "You have received a trade request from " .. senderName, "success", 5000)
end)

RegisterNetEvent("codev-trade:openTrade", function()
    triggerServerCallback("codev-trade:getPlayerItems", function(cb)
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = "setItems",
            items = cb,
            imgLocation = Config.ImagesLocation,
            acceptTime = Config.AcceptTime
        })
    end)
end)

RegisterNetEvent("codev-trade:notify", function(title, message, type, length)
    Config.Notify(title, message, type, length)
end)

RegisterNuiCallback("acceptOffer", function(status)
    TriggerServerEvent("codev-trade:acceptOffer", status)
end)

RegisterNuiCallback("refreshItems", function(data)
    local html = data.html
    local items = data.items
    TriggerServerEvent("codev-trade:refreshItems", html, items)
end)

RegisterNuiCallback("cancelTrade", function()
    TriggerServerEvent("codev-trade:cancelTrade")
    SetNuiFocus(false, false)
end)

RegisterNetEvent("codev-trade:refreshItems", function(html)
    SendNUIMessage({
        action = "refreshOfferedItems",
        html = html,
        imgLocation = Config.ImagesLocation
    })
end)

RegisterNetEvent("codev-trade:sendTime", function(time)
    SendNUIMessage({
        action = "sendTime",
        time = time
    })
end)

RegisterNetEvent("codev-trade:sendStatus", function(status)
    SendNUIMessage({
        action = "sendStatus",
        status = status
    })
end)

RegisterNetEvent("codev-trade:endTrade", function()
    requestReceived = false
    sender = nil
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = "end",
    })
end)
local Trades = {}

registerServerCallback('codev-trade:getPlayerItems', function(src, cb)
    local Player = Config.Framework == "qb" and Framework.Functions.GetPlayer(src) or Framework.GetPlayer(src)
    local itemlist = {}

    if Config.Framework == "esx" then
        for k,v in pairs(Player.inventory) do
            itemlist[k] = {
                count = v.count,
                label = v.label,
                image = v.image,
                name = v.name,
            }
        end
    else
        local inv = Player.PlayerData.items
        for k,v in pairs(inv) do
            Wait(5)
            local item = Player.Functions.GetItemByName(v.name)
            itemlist[k] = {
                count = item.amount,
                label = item.label,
                image = item.image,
                name = item.name,
            }
        end
    end

    cb(itemlist)
end)

registerServerCallback('codev-trade:checkIsOnline', function(src, cb, id)
    if GetPlayerPed(id) ~= 0 then
        cb(true)
    else
        cb(false)
    end
end)

RegisterServerEvent('codev-trade:sendRequest', function(id)
    local receiver = id
    local sender = source
    
    for k,v in pairs(Trades) do
        if v.sender.id == sender then
            TriggerClientEvent('codev-trade:notify', sender, 'Error', 'You have already sent a trade request', 'error', 5000)
            return
        end
    end

    for k,v in pairs(Trades) do
        if v.receiver.id == receiver then
            TriggerClientEvent('codev-trade:notify', sender, 'Error', 'This player already have a trade on going!', 'error', 5000)
            return
        end
    end

    table.insert(Trades, {
        tradeId = sender,
        time = Config.AcceptTime,
        started = false,

        sender = {
            id = sender,
            name = GetPlayerName(sender),
            offered = {},
            accepted = false
        },
        receiver = {
            id = receiver,
            name = GetPlayerName(receiver),
            offered = {},
            accepted = false
        }
    })

    TriggerClientEvent('codev-trade:notify', id, "Sent", "Trade request sent!", "success", 5000)
    TriggerClientEvent('codev-trade:requestReceived', receiver, sender, GetPlayerName(sender))
end)

RegisterServerEvent('codev-trade:declineRequest', function(sender)
    for k,v in pairs(Trades) do
        if v.sender.id == sender then
            TriggerClientEvent('codev-trade:notify', v.sender.id, 'Declined', 'They have declined the trade request', 'error', 5000)
            TriggerClientEvent('codev-trade:notify', v.receiver.id, 'Declined', 'You have declined the trade request', 'error', 5000)
            table.remove(Trades, k)
        end
    end
end)

RegisterServerEvent('codev-trade:acceptRequest', function(sender)
    local sender = sender
    local receiver = source

    for k,v in pairs(Trades) do
        if v.sender.id == sender and v.receiver.id == receiver then
            TriggerClientEvent('codev-trade:openTrade', sender)
            Wait(20)
            TriggerClientEvent('codev-trade:openTrade', receiver)
        end
    end
end)

RegisterServerEvent('codev-trade:refreshItems', function(html, items)
    local src = source

    for k,v in pairs(Trades) do
        if v.sender.id == src then
            v.sender.offered = items
            TriggerClientEvent("codev-trade:refreshItems", v.receiver.id, html)
        elseif v.receiver.id == src then
            v.receiver.offered = items
            TriggerClientEvent("codev-trade:refreshItems", v.sender.id, html)
        end
    end
end)

RegisterServerEvent('codev-trade:cancelTrade', function()
    local src = source

    for k,v in pairs(Trades) do
        if v.sender.id == src then
            if v.started then
                v.sender.accepted = false
            else
                TriggerClientEvent('codev-trade:cancelTrade', v.receiver.id)
                table.remove(Trades, k)
            end
        elseif v.receiver.id == src then
            if v.started then
                v.receiver.accepted = false
            else
                TriggerClientEvent('codev-trade:cancelTrade', v.sender.id)
                table.remove(Trades, k)
            end
        end
    end
end)

RegisterServerEvent('codev-trade:acceptOffer', function(status)
    local src = source
    local sender = nil
    local receiver = nil

    for k,v in pairs(Trades) do
        if v.sender.id == src then
            v.sender.accepted = status.accepted
            TriggerClientEvent('codev-trade:sendStatus', v.receiver.id, status.accepted)
        elseif v.receiver.id == src then
            v.receiver.accepted = status.accepted
            TriggerClientEvent('codev-trade:sendStatus', v.sender.id, status.accepted)
        end

        if v.sender.id == src or v.receiver.id == src and v.time == Config.AcceptTime then
            sender = Config.Framework == "qb" and Framework.Functions.GetPlayer(v.sender.id) or Framework.GetPlayer(v.sender.id)
            receiver = Config.Framework == "qb" and Framework.Functions.GetPlayer(v.receiver.id) or Framework.GetPlayer(v.receiver.id)

            if v.receiver.accepted and v.sender.accepted then
                v.started = true

                while true do
                    if not v.receiver.accepted or not v.sender.accepted then
                        TriggerClientEvent('codev-trade:notify', v.sender.id, 'Error', 'Trade canceled!', 'error', 5000)
                        TriggerClientEvent('codev-trade:notify', v.receiver.id, 'Error', 'Trade canceled!', 'error', 5000)
                        TriggerClientEvent('codev-trade:endTrade', v.sender.id)
                        TriggerClientEvent('codev-trade:endTrade', v.receiver.id)
                        table.remove(Trades, k)
                        break
                    end

                    TriggerClientEvent('codev-trade:sendTime', v.sender.id, v.time)
                    TriggerClientEvent('codev-trade:sendTime', v.receiver.id, v.time)

                    v.time = v.time - 1
                    Wait(1000)

                    if v.time == 0 then
                        for k,v in pairs(v.sender.offered) do
                            Wait(5)
                            if Config.Framework == "qb" then
                                sender.Functions.RemoveItem(v.name, v.count)
                                receiver.Functions.AddItem(v.name, v.count)
                            else
                                sender.removeInventoryItem(v.name, v.count)
                                receiver.addInventoryItem(v.name, v.count)
                            end
                        end

                        for k,v in pairs(v.receiver.offered) do
                            if Config.Framework == "qb" then
                                receiver.Functions.RemoveItem(v.name, v.count)
                                sender.Functions.AddItem(v.name, v.count)
                            else
                                receiver.removeInventoryItem(v.name, v.count)
                                sender.addInventoryItem(v.name, v.count)
                            end
                        end

                        TriggerClientEvent('codev-trade:notify', v.sender.id, 'Success', 'Trade completed!', 'success', 5000)
                        TriggerClientEvent('codev-trade:notify', v.receiver.id, 'Success', 'Trade completed!', 'success', 5000)
                        TriggerClientEvent('codev-trade:endTrade', v.sender.id)
                        TriggerClientEvent('codev-trade:endTrade', v.receiver.id)
                        table.remove(Trades, k)
                        break
                    end
                end
            end
        end
    end
end)
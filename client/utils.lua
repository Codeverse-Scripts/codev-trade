Framework = Config.Framework == "esx" and exports['es_extended']:getSharedObject() or exports["qb-core"]:GetCoreObject()

function triggerServerCallback(...)
    if Config.Framework == "esx" then
        Framework.TriggerServerCallback(...)
    else
        Framework.Functions.TriggerCallback(...)
    end
end
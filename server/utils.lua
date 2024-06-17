Framework = Config.Framework == "esx" and exports['es_extended']:getSharedObject() or exports["qb-core"]:GetCoreObject()

function registerServerCallback(...)
    if Config.Framework == "esx" then
        Framework.RegisterServerCallback(...)
    else
        Framework.Functions.CreateCallback(...)
    end
end
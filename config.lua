Config = {
    Framework = "qb", -- qb / esx
    ImagesLocation = "https://cfx-nui-qb-inventory/html/images/",
    AcceptTime = 10, -- Seconds

    Notify = function(title, message, type, length)
        if Config.Framework == "esx" then
            Framework.ShowNotification(message)
        else
            Framework.Functions.Notify(message, type, length)
        end
    end
}
-- AURA Phone v2 - App Store
addEvent("phone:store:list", true)
addEventHandler("phone:store:list", root, function(list)
    Phone.data.store = list or {}
end)

addEvent("phone:store:state", true)
addEventHandler("phone:store:state", root, function(appId, installed)
    Phone.data.installed[appId] = installed == 1
    for _, s in ipairs(Phone.data.store) do
        if s.id == appId then s.installed = installed == 1 end
    end
end)

registerPhoneApp({
    id = "store",
    name = "App Store",
    onOpen = function()
        triggerServerEvent("phone:store:fetch")
    end,
    render = function()
        D.rrect(0, 0, 360, 740, 0, D.t().screen)
        D.header(L("store"))

        D.rrect(16, 74, 328, 84, 18, D.mix(D.t().info, { 18, 22, 36, 255 }, 0.3))
        D.icon(Phone.img["assets/icons/store.png"], "Store", 32, 92, 48)
        D.text(L("store"), 94, 90, { size = 15, bold = true })
        D.text(L("storeSub"), 94, 116, { size = 10.5, color = D.t().sub })

        local list = Phone.data.store
        if #list == 0 then
            D.spinner(160, 300, 40)
        else
            D.list("store.list", 14, 174, 332, 740 - 174 - 18, #list, 86, function(i, y)
                local s = list[i]
                D.rrect(16, y + 3, 328, 80, 14, D.t().card)
                local app = PhoneAppMap[s.id]
                D.icon(app and Phone.img[app.icon], s.name, 30, y + 16, 52)
                D.text(s.name, 96, y + 14, { size = 13, bold = true, h = 22 })
                D.text(s.desc or "", 96, y + 36, { size = 10, color = D.t().sub, w = 170, h = 30, wrap = true })
                if s.soon then
                    D.rrect(272, y + 26, 58, 28, 14, { 80, 88, 108, 120 })
                    D.text(L("soon"), 272, y + 26, { w = 58, size = 10.5, align = "center", valign = "middle", color = { 255, 255, 255, 160 }, bold = true })
                elseif s.installed then
                    D.btn(262, y + 16, 68, 32, function()
                        openApp(s.id)
                    end, { style = "ghost", label = L("open"), size = 11 })
                    D.zone(262, y + 52, 68, 20, function()
                        triggerServerEvent("phone:store:toggle", s.id)
                    end)
                    D.text(L("remove"), 262, y + 54, { w = 68, size = 9, align = "center", color = D.t().danger, h = 14 })
                else
                    D.btn(262, y + 16, 68, 32, function()
                        triggerServerEvent("phone:store:toggle", s.id)
                    end, { style = "primary", label = L("get"), size = 11 })
                end
            end)
        end
    end,
})
